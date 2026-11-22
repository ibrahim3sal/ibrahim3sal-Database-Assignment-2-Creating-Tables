## Hand trace for nums = [1, 2, 3, 4]:
Prefix pass (prefix[0] = 1):
i = 0 (nums[0] = 1): prefix[0] = 1, product = 1
i = 1 (nums[1] = 2): prefix[1] = 1, product = 2
i = 2 (nums[2] = 3): prefix[2] = 2, product = 6
i = 3 (nums[3] = 4): prefix[3] = 6, product = 24
prefix = [1, 1, 2, 6]

Suffix pass (suffix[3] = 1):
i = 3 (nums[3] = 4): suffix[3] = 1, product = 4
i = 2 (nums[2] = 3): suffix[2] = 4, product = 12
i = 1 (nums[1] = 2): suffix[1] = 12, product = 24
i = 0 (nums[0] = 1): suffix[0] = 24, product = 24
suffix = [24, 12, 4, 1]

Combine (answer[i] = prefix[i] * suffix[i]):
i = 0: 1 * 24 = 24
i = 1: 1 * 12 = 12
i = 2: 2 * 4 = 8
i = 3: 6 * 1 = 6
Output: [24, 12, 8, 6]

BidNile — Notes & Short Answers
1. Your 4 schemas, their tables, and why
Identity: City, Member, Warehouse, WarehouseEmployee — groups user accounts, locations/cities, physical warehouses, and warehouse staff/management.

Catalog: Category, Item, ItemPhoto — groups merchandise categories, listed items, and item photos.

Auction: Auction, Bid, FollowedAuction (moved to Marketing in 3.12) — groups active/past auctions, bids placed on them, and auction following.

Finance: Wallet — isolates balances, held funds, and currency logic from catalog and auction tables.

2. Relationship types in BidNile and how they were mapped
1:1: Member ↔ Wallet — mapped with MemberId as a foreign key in Wallet restricted by a UNIQUE constraint (UQ_Wallet_MemberId) so each member can have at most one wallet.

1:N: City → Member, City → Warehouse, Category → Item, Item → Auction, Auction → Bid, and Member → Bid — mapped by placing a foreign key on the "many" (child) table referencing the primary key of the "one" (parent) table.

M:N: Member and Warehouse via WarehouseEmployee, and Member and Auction via FollowedAuction — mapped using junction (bridge) tables with a composite primary key (MemberId, WarehouseId) and (MemberId, AuctionId).

Recursive: Member.ReferredByMemberId → Member.MemberId (member referrals) and Category.ParentCategoryCode → Category.CategoryCode (parent/sub-categories) — mapped as self-referencing foreign keys pointing to the primary key of the same table.

Circular: Member ↔ Warehouse (Warehouse.ManagerMemberId references Member.MemberId, while Member can be linked to a city/warehouse context and Item references both Member and Warehouse) — mapped via foreign keys added cleanly after table creation rather than tightly coupled inline definitions.

Weak entity: ItemPhoto depends on Item — mapped with a composite primary key (ItemId, PhotoOrder) where ItemId is both part of the PK and a FOREIGN KEY referencing Item.ItemId with ON DELETE CASCADE.

3. Data type choices
GUID (UNIQUEIDENTIFIER) for Member: avoids predictable sequential IDs for user accounts and supports safe distributed/client-side ID generation (NEWID()).

BIGINT for Bid: bid volume grows rapidly over time across many auctions, so BIGINT prevents integer overflow (INT max ~2.14 billion).

FLOAT for GPS (Latitude, Longitude): geographic coordinates are approximate floating-point measurements where compact storage and range fit well.

DECIMAL for money (StartingPrice, ReservePrice, BidIncrement, BuyNowPrice, Balance, HeldAmount, CommissionRate): binary floating-point (FLOAT) introduces rounding errors; DECIMAL(p,s) preserves exact base-10 financial precision.

DATETIMEOFFSET for auctions (StartAt, EndAt): preserves the exact instant plus the time-zone offset, which is essential when bidders and auctions span different time zones or daylight/offset contexts.

4. Why the circular relationship can't be created inside CREATE TABLE
When two or more tables reference each other in a cycle (for example Warehouse referencing Member and Member / related entities referencing back, or self/multi-table cycles), creating all foreign keys inline during CREATE TABLE forces an ordering/dependency bottleneck where a referenced table or constraint does not exist yet at creation time. Adding foreign keys in ALTER TABLE (Task 3.1) after all tables exist avoids chicken-and-egg creation failures and keeps creation scripts clean and predictable.

5. Order of filling tables and why
Tables are populated in parent-before-child dependency order so every FOREIGN KEY constraint is satisfied when inserted:

Independent lookup/base tables first: City, Category, Member (with root/non-referred members first, then referred members).

Tables referencing City and Member: Warehouse, WarehouseEmployee, Wallet.

Item (referencing Member, Category, Warehouse), then ItemPhoto (referencing Item).

Auction (referencing Item), then Bid and FollowedAuction (referencing Auction and Member).

6. Errors in 3.6 and 3.11, and how they were fixed
3.6 (MaxItems → SMALLINT keeping greater than 0): altering a column or modifying constraints fails when an existing CHECK constraint or dependent object is attached or when values/types conflict. Fix: drop the existing CHECK constraint on the column, ALTER COLUMN to SMALLINT NOT NULL (max 32,767, fitting 30,000), and re-add the named CHECK constraint (greater than 0).

3.11 (Adding VerifiedAt and dropping IsVerified): SQL Server blocks dropping a column (ALTER TABLE ... DROP COLUMN IsVerified) if a DEFAULT constraint (DF_Member_IsVerified) is attached to it (Msg 5074 / dependency error). Fix: add VerifiedAt, drop DF_Member_IsVerified first using ALTER TABLE ... DROP CONSTRAINT, and then drop IsVerified.
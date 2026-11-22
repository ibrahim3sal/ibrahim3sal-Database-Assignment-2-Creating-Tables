CREATE DATABASE BidNile;
GO

USE BidNile;
GO

CREATE SCHEMA [Identity];
GO

CREATE SCHEMA Catalog;
GO

CREATE SCHEMA Auction;
GO

CREATE SCHEMA Finance;
GO

-- 1. Identity.City (PK INT IDENTITY + CHAR(2) + Single & Composite UNIQUE + CHECK ... IN)
CREATE TABLE [Identity].City
(
    CityId INT IDENTITY(1, 1) NOT NULL,
    Name NVARCHAR(60) NOT NULL,
    CountryCode CHAR(2) NOT NULL,
    CONSTRAINT PK_City PRIMARY KEY (CityId),
    CONSTRAINT UQ_City_CityId UNIQUE (CityId),
    CONSTRAINT UQ_City_Name_CountryCode UNIQUE (Name, CountryCode),
    CONSTRAINT CK_City_CountryCode CHECK (CountryCode IN ('EG', 'SA', 'AE'))
);
GO

-- 2. Identity.Member (PK UNIQUEIDENTIFIER + DEFAULT constant & function + DATETIME2(3) + DATE + BIT + VARCHAR + NVARCHAR)
CREATE TABLE [Identity].Member
(
    MemberId UNIQUEIDENTIFIER NOT NULL
        CONSTRAINT DF_Member_MemberId DEFAULT (NEWID()),
    CityId INT NOT NULL,
    ReferredByMemberId UNIQUEIDENTIFIER NULL,
    FullName NVARCHAR(100) NOT NULL,
    Email VARCHAR(254) NOT NULL,
    MobileNumber VARCHAR(16) NOT NULL,
    NationalIdOrPassport VARCHAR(20) NOT NULL,
    BirthDate DATE NOT NULL,
    IsVerified BIT NOT NULL
        CONSTRAINT DF_Member_IsVerified DEFAULT (0),
    RegisteredAt DATETIME2(3) NOT NULL
        CONSTRAINT DF_Member_RegisteredAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_Member PRIMARY KEY (MemberId),
    CONSTRAINT UQ_Member_Email UNIQUE (Email),
    CONSTRAINT UQ_Member_NationalIdOrPassport UNIQUE (NationalIdOrPassport),
    CONSTRAINT CK_Member_MobileNumber CHECK (MobileNumber LIKE '+%'),
    CONSTRAINT CK_Member_BirthDate CHECK (BirthDate <= DATEADD(YEAR, -18, CAST(SYSUTCDATETIME() AS DATE)))
);
GO

-- 3. Identity.Warehouse (PK INT IDENTITY + FLOAT + Table-level CHECK + UNIQUE)
CREATE TABLE [Identity].Warehouse
(
    WarehouseId INT IDENTITY(1, 1) NOT NULL,
    Name NVARCHAR(80) NOT NULL,
    Capacity INT NOT NULL,
    CityId INT NOT NULL,
    Latitude FLOAT NOT NULL,
    Longitude FLOAT NOT NULL,
    ManagerMemberId UNIQUEIDENTIFIER NULL,
    ManagerStartDate DATE NULL,
    CONSTRAINT PK_Warehouse PRIMARY KEY (WarehouseId),
    CONSTRAINT UQ_Warehouse_Name UNIQUE (Name),
    CONSTRAINT CK_Warehouse_Capacity CHECK (Capacity > 0),
    CONSTRAINT CK_Warehouse_Coordinates CHECK (Latitude BETWEEN -90.0 AND 90.0 AND Longitude BETWEEN -180.0 AND 180.0)
);
GO

-- 4. Identity.WarehouseEmployee (Composite PK + UNIQUE)
CREATE TABLE [Identity].WarehouseEmployee
(
    MemberId UNIQUEIDENTIFIER NOT NULL,
    WarehouseId INT NOT NULL,
    CONSTRAINT PK_WarehouseEmployee PRIMARY KEY (MemberId, WarehouseId),
    CONSTRAINT UQ_WarehouseEmployee_MemberId UNIQUE (MemberId)
);
GO

-- 5. Catalog.Category (PK INT without IDENTITY + TINYINT + DECIMAL(p,s) + UNIQUE)
CREATE TABLE Catalog.Category
(
    CategoryCode INT NOT NULL,
    ParentCategoryCode INT NULL,
    NameEn NVARCHAR(50) NOT NULL,
    NameAr NVARCHAR(50) NOT NULL,
    CommissionRate DECIMAL(5, 2) NOT NULL,
    CONSTRAINT PK_Category PRIMARY KEY (CategoryCode),
    CONSTRAINT UQ_Category_NameEn UNIQUE (NameEn),
    CONSTRAINT CK_Category_CodeRange CHECK (CategoryCode > 0),
    CONSTRAINT CK_Category_CommissionRate CHECK (CommissionRate >= 0.00 AND CommissionRate <= 30.00)
);
GO

-- 6. Catalog.Item (TINYINT + NVARCHAR(MAX) + JSON check + Table-level CHECK)
CREATE TABLE Catalog.Item
(
    ItemId UNIQUEIDENTIFIER NOT NULL
        CONSTRAINT DF_Item_ItemId DEFAULT (NEWID()),
    SellerMemberId UNIQUEIDENTIFIER NOT NULL,
    InspectorMemberId UNIQUEIDENTIFIER NOT NULL,
    CategoryCode INT NOT NULL,
    WarehouseId INT NULL,
    Title NVARCHAR(150) NOT NULL,
    Description NVARCHAR(MAX) NULL,
    ConditionScore TINYINT NOT NULL,
    SpecificationsJson NVARCHAR(MAX) NOT NULL,
    ListedAt DATETIME2(3) NOT NULL
        CONSTRAINT DF_Item_ListedAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_Item PRIMARY KEY (ItemId),
    CONSTRAINT CK_Item_ConditionScore CHECK (ConditionScore BETWEEN 1 AND 10),
    CONSTRAINT CK_Item_SpecificationsJson CHECK (ISJSON(SpecificationsJson) = 1),
    CONSTRAINT CK_Item_SellerNotInspector CHECK (SellerMemberId <> InspectorMemberId)
);
GO

-- 7. Catalog.ItemPhoto (Composite PK + TINYINT + DEFAULT constant + Table-level CHECK)
CREATE TABLE Catalog.ItemPhoto
(
    ItemId UNIQUEIDENTIFIER NOT NULL,
    PhotoOrder TINYINT NOT NULL,
    PhotoUrl VARCHAR(500) NOT NULL,
    IsMain BIT NOT NULL
        CONSTRAINT DF_ItemPhoto_IsMain DEFAULT (0),
    CONSTRAINT PK_ItemPhoto PRIMARY KEY (ItemId, PhotoOrder),
    CONSTRAINT CK_ItemPhoto_PhotoOrder CHECK (PhotoOrder BETWEEN 1 AND 20),
    CONSTRAINT CK_ItemPhoto_PhotoUrl CHECK (LEN(LTRIM(RTRIM(PhotoUrl))) > 0)
);
GO

-- 8. Auction.Auction (PK BIGINT IDENTITY + DECIMAL(p,s) + DATETIMEOFFSET + DEFAULT constant + CHECK ... IN + Table-level CHECK)
CREATE TABLE Auction.Auction
(
    AuctionId BIGINT IDENTITY(1, 1) NOT NULL,
    ItemId UNIQUEIDENTIFIER NOT NULL,
    StartingPrice DECIMAL(12, 2) NOT NULL,
    ReservePrice DECIMAL(12, 2) NULL,
    BidIncrement DECIMAL(12, 2) NOT NULL
        CONSTRAINT DF_Auction_BidIncrement DEFAULT (50.00),
    StartAt DATETIMEOFFSET NOT NULL,
    EndAt DATETIMEOFFSET NOT NULL,
    Status VARCHAR(10) NOT NULL
        CONSTRAINT DF_Auction_Status DEFAULT ('Draft'),
    CONSTRAINT PK_Auction PRIMARY KEY (AuctionId),
    CONSTRAINT CK_Auction_StartingPrice CHECK (StartingPrice > 0.00),
    CONSTRAINT CK_Auction_ReservePrice CHECK (ReservePrice IS NULL OR ReservePrice >= StartingPrice),
    CONSTRAINT CK_Auction_BidIncrement CHECK (BidIncrement > 0.00),
    CONSTRAINT CK_Auction_Status CHECK (Status IN ('Draft', 'Live', 'Ended', 'Cancelled')),
    CONSTRAINT CK_Auction_TimeWindow CHECK (EndAt > StartAt)
);
GO

-- 9. Auction.Bid (PK BIGINT IDENTITY + Composite UNIQUE + DATETIME2(3) + VARCHAR)
CREATE TABLE Auction.Bid
(
    BidId BIGINT IDENTITY(1, 1) NOT NULL,
    AuctionId BIGINT NOT NULL,
    BidderMemberId UNIQUEIDENTIFIER NOT NULL,
    Amount DECIMAL(12, 2) NOT NULL,
    PlacedAt DATETIME2(3) NOT NULL
        CONSTRAINT DF_Bid_PlacedAt DEFAULT (SYSUTCDATETIME()),
    IpAddress VARCHAR(45) NOT NULL,
    CONSTRAINT PK_Bid PRIMARY KEY (BidId),
    CONSTRAINT UQ_Bid_AuctionId_Amount UNIQUE (AuctionId, Amount),
    CONSTRAINT CK_Bid_Amount CHECK (Amount > 0.00),
    CONSTRAINT CK_Bid_IpAddress CHECK (LEN(LTRIM(RTRIM(IpAddress))) > 0)
);
GO

-- 10. Auction.FollowedAuction (Composite PK + DATETIME2(3) + DEFAULT function)
CREATE TABLE Auction.FollowedAuction
(
    MemberId UNIQUEIDENTIFIER NOT NULL,
    AuctionId BIGINT NOT NULL,
    FollowedAt DATETIME2(3) NOT NULL
        CONSTRAINT DF_FollowedAuction_FollowedAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_FollowedAuction PRIMARY KEY (MemberId, AuctionId)
);
GO

-- 11. Finance.Wallet (PK UNIQUEIDENTIFIER + SINGLE UNIQUE + DECIMAL(12,2) + CHAR(3) + DEFAULT constant & function + Table-level CHECK)
CREATE TABLE Finance.Wallet
(
    WalletId UNIQUEIDENTIFIER NOT NULL
        CONSTRAINT DF_Wallet_WalletId DEFAULT (NEWID()),
    MemberId UNIQUEIDENTIFIER NOT NULL,
    Balance DECIMAL(12, 2) NOT NULL
        CONSTRAINT DF_Wallet_Balance DEFAULT (0.00),
    HeldAmount DECIMAL(12, 2) NOT NULL
        CONSTRAINT DF_Wallet_HeldAmount DEFAULT (0.00),
    Currency CHAR(3) NOT NULL
        CONSTRAINT DF_Wallet_Currency DEFAULT ('EGP'),
    UpdatedAt DATETIME2(3) NOT NULL
        CONSTRAINT DF_Wallet_UpdatedAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_Wallet PRIMARY KEY (WalletId),
    CONSTRAINT UQ_Wallet_MemberId UNIQUE (MemberId),
    CONSTRAINT CK_Wallet_Balance CHECK (Balance >= 0.00 AND Balance <= 9999999999.99),
    CONSTRAINT CK_Wallet_HeldAmount CHECK (HeldAmount >= 0.00 AND HeldAmount <= Balance)
);
GO

-- 3.1 Connect everything (ON DELETE CASCADE for ItemPhoto; NO ACTION for all other FKs)
ALTER TABLE [Identity].Member
    ADD CONSTRAINT FK_Member_City FOREIGN KEY (CityId)
        REFERENCES [Identity].City (CityId) ON DELETE NO ACTION;
GO

ALTER TABLE [Identity].Member
    ADD CONSTRAINT FK_Member_ReferredByMember FOREIGN KEY (ReferredByMemberId)
        REFERENCES [Identity].Member (MemberId) ON DELETE NO ACTION;
GO

ALTER TABLE [Identity].Warehouse
    ADD CONSTRAINT FK_Warehouse_City FOREIGN KEY (CityId)
        REFERENCES [Identity].City (CityId) ON DELETE NO ACTION;
GO

ALTER TABLE [Identity].Warehouse
    ADD CONSTRAINT FK_Warehouse_ManagerMember FOREIGN KEY (ManagerMemberId)
        REFERENCES [Identity].Member (MemberId) ON DELETE NO ACTION;
GO

ALTER TABLE [Identity].WarehouseEmployee
    ADD CONSTRAINT FK_WarehouseEmployee_Member FOREIGN KEY (MemberId)
        REFERENCES [Identity].Member (MemberId) ON DELETE NO ACTION;
GO

ALTER TABLE [Identity].WarehouseEmployee
    ADD CONSTRAINT FK_WarehouseEmployee_Warehouse FOREIGN KEY (WarehouseId)
        REFERENCES [Identity].Warehouse (WarehouseId) ON DELETE NO ACTION;
GO

ALTER TABLE Catalog.Category
    ADD CONSTRAINT FK_Category_ParentCategory FOREIGN KEY (ParentCategoryCode)
        REFERENCES Catalog.Category (CategoryCode) ON DELETE NO ACTION;
GO

ALTER TABLE Catalog.Item
    ADD CONSTRAINT FK_Item_SellerMember FOREIGN KEY (SellerMemberId)
        REFERENCES [Identity].Member (MemberId) ON DELETE NO ACTION;
GO

ALTER TABLE Catalog.Item
    ADD CONSTRAINT FK_Item_InspectorMember FOREIGN KEY (InspectorMemberId)
        REFERENCES [Identity].Member (MemberId) ON DELETE NO ACTION;
GO

ALTER TABLE Catalog.Item
    ADD CONSTRAINT FK_Item_Category FOREIGN KEY (CategoryCode)
        REFERENCES Catalog.Category (CategoryCode) ON DELETE NO ACTION;
GO

ALTER TABLE Catalog.Item
    ADD CONSTRAINT FK_Item_Warehouse FOREIGN KEY (WarehouseId)
        REFERENCES [Identity].Warehouse (WarehouseId) ON DELETE NO ACTION;
GO

ALTER TABLE Catalog.ItemPhoto
    ADD CONSTRAINT FK_ItemPhoto_Item FOREIGN KEY (ItemId)
        REFERENCES Catalog.Item (ItemId) ON DELETE CASCADE;
GO

ALTER TABLE Auction.Auction
    ADD CONSTRAINT FK_Auction_Item FOREIGN KEY (ItemId)
        REFERENCES Catalog.Item (ItemId) ON DELETE NO ACTION;
GO

ALTER TABLE Auction.Bid
    ADD CONSTRAINT FK_Bid_Auction FOREIGN KEY (AuctionId)
        REFERENCES Auction.Auction (AuctionId) ON DELETE NO ACTION;
GO

ALTER TABLE Auction.Bid
    ADD CONSTRAINT FK_Bid_BidderMember FOREIGN KEY (BidderMemberId)
        REFERENCES [Identity].Member (MemberId) ON DELETE NO ACTION;
GO

ALTER TABLE Auction.FollowedAuction
    ADD CONSTRAINT FK_FollowedAuction_Member FOREIGN KEY (MemberId)
        REFERENCES [Identity].Member (MemberId) ON DELETE NO ACTION;
GO

ALTER TABLE Auction.FollowedAuction
    ADD CONSTRAINT FK_FollowedAuction_Auction FOREIGN KEY (AuctionId)
        REFERENCES Auction.Auction (AuctionId) ON DELETE NO ACTION;
GO

ALTER TABLE Finance.Wallet
    ADD CONSTRAINT FK_Wallet_Member FOREIGN KEY (MemberId)
        REFERENCES [Identity].Member (MemberId) ON DELETE NO ACTION;
GO

-- 3.2 Members choose an app language, ar or en
ALTER TABLE [Identity].Member
    ADD AppLanguage CHAR(2) NOT NULL
        CONSTRAINT DF_Member_AppLanguage DEFAULT ('ar'),
    CONSTRAINT CK_Member_AppLanguage CHECK (AppLanguage IN ('ar', 'en'));
GO

-- 3.3 Items can be "featured"
ALTER TABLE Catalog.Item
    ADD IsFeatured BIT NOT NULL
        CONSTRAINT DF_Item_IsFeatured DEFAULT (0);
GO

-- 3.4 Naming review: rename IpAddress -> DeviceIp and Capacity -> MaxItems using sp_rename
ALTER TABLE Auction.Bid
    DROP CONSTRAINT CK_Bid_IpAddress;
GO

EXEC sp_rename 'Auction.Bid.IpAddress', 'DeviceIp', 'COLUMN';
GO

ALTER TABLE Auction.Bid
    ADD CONSTRAINT CK_Bid_DeviceIp CHECK (LEN(LTRIM(RTRIM(DeviceIp))) > 0);
GO

ALTER TABLE [Identity].Warehouse
    DROP CONSTRAINT CK_Warehouse_Capacity;
GO

ALTER TABLE [Identity].Warehouse
    DROP CONSTRAINT CK_Warehouse_Coordinates;
GO

EXEC sp_rename '[Identity].Warehouse.Capacity', 'MaxItems', 'COLUMN';
GO

ALTER TABLE [Identity].Warehouse
    ADD CONSTRAINT CK_Warehouse_MaxItems CHECK (MaxItems > 0);
GO

ALTER TABLE [Identity].Warehouse
    ADD CONSTRAINT CK_Warehouse_Coordinates CHECK (Latitude BETWEEN -90.0 AND 90.0 AND Longitude BETWEEN -180.0 AND 180.0);
GO

-- 3.5 Full name up to 150 characters, still NOT NULL
ALTER TABLE [Identity].Member
    ALTER COLUMN FullName NVARCHAR(150) NOT NULL;
GO

-- 3.6 MaxItems up to 30,000 -> SMALLINT (max 32,767). Drop dependent CHECK first, alter column, re-add CHECK (> 0)
ALTER TABLE [Identity].Warehouse
    DROP CONSTRAINT CK_Warehouse_MaxItems;
GO

ALTER TABLE [Identity].Warehouse
    ALTER COLUMN MaxItems SMALLINT NOT NULL;
GO

ALTER TABLE [Identity].Warehouse
    ADD CONSTRAINT CK_Warehouse_MaxItems CHECK (MaxItems > 0);
GO

-- 3.7 Max commission is now 25%
ALTER TABLE Catalog.Category
    DROP CONSTRAINT CK_Category_CommissionRate;
GO

ALTER TABLE Catalog.Category
    ADD CONSTRAINT CK_Category_CommissionRate CHECK (CommissionRate >= 0.00 AND CommissionRate <= 25.00);
GO

-- 3.8 Allow status PendingReview and make it the new default
ALTER TABLE Auction.Auction
    DROP CONSTRAINT DF_Auction_Status;
GO

ALTER TABLE Auction.Auction
    DROP CONSTRAINT CK_Auction_Status;
GO

ALTER TABLE Auction.Auction
    ADD CONSTRAINT DF_Auction_Status DEFAULT ('PendingReview') FOR Status;
GO

ALTER TABLE Auction.Auction
    ADD CONSTRAINT CK_Auction_Status CHECK (Status IN ('PendingReview', 'Draft', 'Live', 'Ended', 'Cancelled'));
GO

-- 3.9 Optional "Buy Now" price + named CHECK (> StartingPrice)
ALTER TABLE Auction.Auction
    ADD BuyNowPrice DECIMAL(12, 2) NULL;
GO

ALTER TABLE Auction.Auction
    WITH CHECK ADD CONSTRAINT CK_Auction_BuyNowPrice CHECK (BuyNowPrice IS NULL OR BuyNowPrice > StartingPrice);
GO

-- 3.10 Member mobile must now be unique
ALTER TABLE [Identity].Member
    ADD CONSTRAINT UQ_Member_MobileNumber UNIQUE (MobileNumber);
GO

-- 3.11 Add VerifiedAt (optional), then drop IsVerified after dropping its attached DEFAULT constraint
ALTER TABLE [Identity].Member
    ADD VerifiedAt DATETIME2(3) NULL;
GO

ALTER TABLE [Identity].Member
    DROP CONSTRAINT DF_Member_IsVerified;
GO

ALTER TABLE [Identity].Member
    DROP COLUMN IsVerified;
GO

-- 3.12 Create schema Marketing and move FollowedAuction into it
CREATE SCHEMA Marketing;
GO

ALTER SCHEMA Marketing TRANSFER OBJECT::Auction.FollowedAuction;
GO
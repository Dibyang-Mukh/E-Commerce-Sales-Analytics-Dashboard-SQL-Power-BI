/* ============================================================
   E-COMMERCE SALES ANALYSIS PROJECT
   Database: Microsoft SQL Server
   Author: Your Name
   Description: End-to-end e-commerce analytics solution
============================================================ */

/* ============================================================
   1️⃣ DATABASE CREATION
============================================================ */

CREATE DATABASE Ecommerce;
GO

USE Ecommerce;
GO

/* ============================================================
   2️⃣ TABLE CREATION
============================================================ */

CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY IDENTITY(1,1),
    CustomerName VARCHAR(100) NOT NULL,
    Gender VARCHAR(10),
    City VARCHAR(50),
    State VARCHAR(50),
    JoinDate DATE
);

CREATE TABLE Products (
    ProductID INT PRIMARY KEY IDENTITY(1,1),
    ProductName VARCHAR(100) NOT NULL,
    Category VARCHAR(50),
    Price DECIMAL(10,2) NOT NULL
);

CREATE TABLE Orders (
    OrderID INT PRIMARY KEY IDENTITY(1,1),
    CustomerID INT,
    OrderDate DATE,
    OrderStatus VARCHAR(20),
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
);

CREATE TABLE OrderDetails (
    OrderDetailID INT PRIMARY KEY IDENTITY(1,1),
    OrderID INT,
    ProductID INT,
    Quantity INT,
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID),
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);

/* ============================================================
   3️⃣ BULK DATA GENERATION
============================================================ */

-- Generate 1000 Customers
WITH Numbers AS (
    SELECT TOP 1000 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS num
    FROM sys.objects a CROSS JOIN sys.objects b
)
INSERT INTO Customers (CustomerName, Gender, City, State, JoinDate)
SELECT 
    CONCAT('Customer_', num),
    CASE WHEN num % 2 = 0 THEN 'Male' ELSE 'Female' END,
    CASE 
        WHEN num % 5 = 0 THEN 'Delhi'
        WHEN num % 5 = 1 THEN 'Mumbai'
        WHEN num % 5 = 2 THEN 'Bangalore'
        WHEN num % 5 = 3 THEN 'Chennai'
        ELSE 'Kolkata'
    END,
    CASE 
        WHEN num % 5 = 0 THEN 'Delhi'
        WHEN num % 5 = 1 THEN 'Maharashtra'
        WHEN num % 5 = 2 THEN 'Karnataka'
        WHEN num % 5 = 3 THEN 'Tamil Nadu'
        ELSE 'West Bengal'
    END,
    DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 1000, GETDATE())
FROM Numbers;


-- Generate 100 Products
WITH Numbers AS (
    SELECT TOP 100 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS num
    FROM sys.objects
)
INSERT INTO Products (ProductName, Category, Price)
SELECT 
    CONCAT('Product_', num),
    CASE 
        WHEN num % 4 = 0 THEN 'Electronics'
        WHEN num % 4 = 1 THEN 'Clothing'
        WHEN num % 4 = 2 THEN 'Furniture'
        ELSE 'Accessories'
    END,
    (ABS(CHECKSUM(NEWID())) % 50000) + 500
FROM Numbers;


-- Generate 10,000 Orders
WITH Numbers AS (
    SELECT TOP 10000 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS num
    FROM sys.objects a CROSS JOIN sys.objects b
)
INSERT INTO Orders (CustomerID, OrderDate, OrderStatus)
SELECT 
    (ABS(CHECKSUM(NEWID())) % 1000) + 1,
    DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 730, GETDATE()),
    CASE 
        WHEN num % 10 = 0 THEN 'Cancelled'
        WHEN num % 15 = 0 THEN 'Returned'
        ELSE 'Completed'
    END
FROM Numbers;


-- Generate 25,000 Order Details
WITH Numbers AS (
    SELECT TOP 25000 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS num
    FROM sys.objects a CROSS JOIN sys.objects b
)
INSERT INTO OrderDetails (OrderID, ProductID, Quantity)
SELECT 
    (ABS(CHECKSUM(NEWID())) % 10000) + 1,
    (ABS(CHECKSUM(NEWID())) % 100) + 1,
    (ABS(CHECKSUM(NEWID())) % 5) + 1
FROM Numbers;


/* ============================================================
   4️⃣ INDEX OPTIMIZATION (Performance Tuning)
============================================================ */

CREATE INDEX idx_orders_customerid ON Orders(CustomerID);
CREATE INDEX idx_orders_orderdate ON Orders(OrderDate);
CREATE INDEX idx_orderdetails_orderid ON OrderDetails(OrderID);
CREATE INDEX idx_products_category ON Products(Category);


/* ============================================================
   5️⃣ BUSINESS ANALYSIS QUERIES
============================================================ */

-- 🔹 Monthly Revenue Trend
SELECT 
    FORMAT(o.OrderDate, 'yyyy-MM') AS Month,
    SUM(od.Quantity * p.Price) AS MonthlyRevenue
FROM Orders o
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID
WHERE o.OrderStatus = 'Completed'
GROUP BY FORMAT(o.OrderDate, 'yyyy-MM')
ORDER BY Month;


-- 🔹 Category-wise Revenue
SELECT 
    p.Category,
    SUM(od.Quantity * p.Price) AS CategoryRevenue
FROM Orders o
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID
WHERE o.OrderStatus = 'Completed'
GROUP BY p.Category
ORDER BY CategoryRevenue DESC;


-- 🔹 Top 5 Customers by Total Spending
WITH CustomerSales AS (
    SELECT 
        c.CustomerName,
        SUM(od.Quantity * p.Price) AS TotalSpent
    FROM Customers c
    JOIN Orders o ON c.CustomerID = o.CustomerID
    JOIN OrderDetails od ON o.OrderID = od.OrderID
    JOIN Products p ON od.ProductID = p.ProductID
    WHERE o.OrderStatus = 'Completed'
    GROUP BY c.CustomerName
)
SELECT *
FROM (
    SELECT *,
           RANK() OVER (ORDER BY TotalSpent DESC) AS RankNo
    FROM CustomerSales
) RankedCustomers
WHERE RankNo <= 5;

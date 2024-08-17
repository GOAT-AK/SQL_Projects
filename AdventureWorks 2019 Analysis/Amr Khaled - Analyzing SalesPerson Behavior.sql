-- ~ -- Analyzing SalesPerson Behavior

-- 1. Exploring How Many SalesPersons We Have
-- ~ -- We Have 17 SalesPerson
SELECT 
    COUNT(DISTINCT BusinessEntityID) AS NumberOfSalesPersons
FROM Sales.SalesPerson; 

------------------------------------------------------------------------
-- 2. Exploring How Many Orders By Each SalesPerson
SELECT 
    Soh.SalesPersonID AS SalesPersonID,
    COUNT(Soh.SalesOrderID) AS NumberOfOrders
FROM 
    Sales.SalesOrderHeader AS Soh
WHERE
    SalesPersonID Is Not Null    
GROUP BY 
   Soh.SalesPersonID
ORDER BY 
    NumberOfOrders DESC;

------------------------------------------------------------------------
-- 3. Exploring How Many of them is Active 
-- (We can Categorize our SalesPersons who made more than 100 order AS Active SalesPerson, SalesPerson Who Made 50-100 Order AS Average SalesPerson, And SalesPerson Who Made Less Than 50 Orders  Inactive)
SELECT 
    SalesPersonStatus,
    COUNT(SalesPersonID) AS SalesPersonCount
FROM (
    SELECT 
        SalesPersonID,
        CASE
            WHEN COUNT(SalesOrderID) > 100 THEN 'Active'
            WHEN COUNT(SalesOrderID) BETWEEN 50 AND 100 THEN 'Average'
            ELSE 'Inactive'
        END AS SalesPersonStatus
    FROM 
        Sales.SalesOrderHeader
    GROUP BY 
        SalesPersonID
) AS CategorizedSalesPersons
GROUP BY 
    SalesPersonStatus;

------------------------------------------------------------------------
-- 4. Who's The Most Ordering SalesPerson
-- ~ -- Jillian Carson With 473 Order
WITH SalesPersonOrderCounts AS (
    SELECT 
        Soh.SalesPersonID,
        CONCAT(P.FirstName, ' ', P.MiddleName, ' ', P.LastName) AS SalesPersonName,
        COUNT(Soh.SalesOrderID) AS NumberOfOrders,
        RANK() OVER (ORDER BY COUNT(Soh.SalesOrderID) DESC) AS OrderRank
    FROM 
        Sales.SalesOrderHeader AS Soh
    JOIN 
        Person.Person AS P ON Soh.SalesPersonID = P.BusinessEntityID
    GROUP BY 
        Soh.SalesPersonID,
        CONCAT(P.FirstName, ' ', P.MiddleName, ' ', P.LastName)
)
SELECT 
    SalesPersonID,
    SalesPersonName,
    NumberOfOrders
FROM 
    SalesPersonOrderCounts
WHERE 
    OrderRank = 1;

------------------------------------------------------------------------
-- 5. Top 5 SalesPersons By Sales
-- ~ -- Linda C Mitchell Achieved more Revenue than Jillian Carson who has more orders
WITH SalesPersonSales AS (
    SELECT
        Soh.SalesPersonID,
        CONCAT(P.FirstName, ' ', P.MiddleName, ' ', P.LastName) AS SalesPersonName,
        SUM(Soh.TotalDue) AS TotalSales
    FROM 
        Sales.SalesOrderHeader AS Soh
    JOIN 
        Person.Person AS P ON Soh.SalesPersonID = P.BusinessEntityID
    GROUP BY 
        Soh.SalesPersonID,
        CONCAT(P.FirstName, ' ', P.MiddleName, ' ', P.LastName)
),
RankedSalesPersons AS (
    SELECT
        SalesPersonID,
        SalesPersonName,
        TotalSales,
        RANK() OVER (ORDER BY TotalSales DESC) AS SalesPersonRank
    FROM 
        SalesPersonSales
)
SELECT
    SalesPersonID,
    SalesPersonName,
    TotalSales
FROM 
    RankedSalesPersons
WHERE 
    SalesPersonRank <= 5;

------------------------------------------------------------------------
-- 6. Exploring Linda And Jillian Sales
-- ~ -- Based on The Results Jillian's AverageOrderValue Is Lower Than Linda, It Indicates That Jillian Handles A Higher Volume Of Smaller-Value Orders.
WITH SalesPersonStats AS (
    SELECT
        Soh.SalesPersonID,
        CONCAT(P.FirstName, ' ', P.MiddleName, ' ', P.LastName) AS SalesPersonName,
        COUNT(Soh.SalesOrderID) AS NumberOfOrders,
        SUM(Soh.TotalDue) AS TotalSales
    FROM 
        Sales.SalesOrderHeader AS Soh
    JOIN 
        Person.Person AS P ON Soh.SalesPersonID = P.BusinessEntityID
    WHERE
        P.FirstName IN ('Linda', 'Jillian')  
    GROUP BY 
        Soh.SalesPersonID,
        CONCAT(P.FirstName, ' ', P.MiddleName, ' ', P.LastName)
)
SELECT
    SalesPersonName,
    NumberOfOrders,
    TotalSales,
    TotalSales / NumberOfOrders AS AverageOrderValue
FROM 
    SalesPersonStats
ORDER BY
    AverageOrderValue DESC;  

------------------------------------------------------------------------
-- 7. SalesPerson Who Achieves The Most Revenue In Each Category 
-- ~ -- Linda Mitchell      Bikes         8660468.696939
-- ~ -- Jae Pak            Components     1571664.977753
-- ~ -- Jae Pak            Clothing       246448.434325
-- ~ -- Jillian Carson     Accessories    73574.549213
WITH SalesPersonProductRevenue AS (
    SELECT 
        Soh.SalesPersonID,
        CONCAT(P.FirstName, ' ', P.LastName) AS SalesPersonName,
        PC.Name AS ProductCategory,
        SUM(Sod.LineTotal) AS TotalRevenue
    FROM 
        Sales.SalesOrderDetail AS Sod
    JOIN 
        Sales.SalesOrderHeader AS Soh ON Sod.SalesOrderID = Soh.SalesOrderID
    JOIN 
        Person.Person AS P ON Soh.SalesPersonID = P.BusinessEntityID
    JOIN 
        Production.Product AS Prod ON Sod.ProductID = Prod.ProductID
    JOIN 
        Production.ProductSubcategory AS PS ON Prod.ProductSubcategoryID = PS.ProductSubcategoryID
    JOIN 
        Production.ProductCategory AS PC ON PS.ProductCategoryID = PC.ProductCategoryID
    GROUP BY 
        Soh.SalesPersonID,
        CONCAT(P.FirstName, ' ', P.LastName),
        PC.Name
),
RankedSalesPersonProducts AS (
    SELECT 
        SalesPersonID,
        SalesPersonName,
        ProductCategory,
        TotalRevenue,
        RANK() OVER (PARTITION BY ProductCategory ORDER BY TotalRevenue DESC) AS RevenueRank
    FROM 
        SalesPersonProductRevenue
)
SELECT 
    SalesPersonID,
    SalesPersonName,
    ProductCategory,
    TotalRevenue
FROM 
    RankedSalesPersonProducts
WHERE 
    RevenueRank = 1
ORDER by   
    TotalRevenue DESC;
    
------------------------------------------------------------------------
-- 8. Exploring Top SalesPerson In Each Territory By Sales To Find The Lowest
-- ~ -- Australia
-- ~ -- Germany
-- ~ -- Central
-- ~ -- Northwest
-- ~ -- United Kingdom
WITH SalesPersonSalesByTerritory AS (
    SELECT
        Soh.SalesPersonID,
        CONCAT(P.FirstName, ' ', P.LastName) AS SalesPersonName,
        ST.Name AS TerritoryName,
        SUM(Soh.TotalDue) AS TotalSales
    FROM 
        Sales.SalesOrderHeader AS Soh
    JOIN 
        Person.Person AS P ON Soh.SalesPersonID = P.BusinessEntityID
    JOIN 
        Sales.SalesTerritory AS ST ON Soh.TerritoryID = ST.TerritoryID
    GROUP BY 
        Soh.SalesPersonID,
        CONCAT(P.FirstName, ' ', P.LastName),
        ST.Name
),
SalesPersonTerritorySales AS (
    SELECT
        SalesPersonName,
        TerritoryName,
        SUM(TotalSales) AS TotalSales
    FROM 
        SalesPersonSalesByTerritory
    GROUP BY 
        SalesPersonName,
        TerritoryName
),
RankedSalesPersons AS (
    SELECT
        SalesPersonName,
        TerritoryName,
        TotalSales,
        RANK() OVER (PARTITION BY TerritoryName ORDER BY TotalSales DESC) AS SalesPersonRank
    FROM 
        SalesPersonTerritorySales
)
SELECT
    SalesPersonName,
    TerritoryName,
    TotalSales
FROM 
    RankedSalesPersons
WHERE 
    SalesPersonRank = 1
ORDER BY
    TotalSales; 

------------------------------------------------------------------------
-- 9. Exploring How Many SalesPerson In Each Territory To See If There's Any Relation Between The Number Of People In Each Territory And The TotalSales
-- ~ -- Australia Have Only 2 SalesPersons Same as United Kingdom
-- ~ -- Central Have 5 SalesPersons And Yet The TotalSales In UnitedKingdom Is Higher, So There's No Relation Between the Number Of People And The TotalSales
WITH SalesPersonByTerritory AS (
    SELECT
        ST.Name AS TerritoryName,
        Soh.SalesPersonID,
        CONCAT(P.FirstName, ' ', P.LastName) AS SalesPersonName
    FROM 
        Sales.SalesOrderHeader AS Soh
    
    JOIN 
        Person.Person AS P ON Soh.SalesPersonID = P.BusinessEntityID
    JOIN 
        Sales.SalesTerritory AS ST ON Soh.TerritoryID = ST.TerritoryID
    GROUP BY 
        ST.Name,
        Soh.SalesPersonID,
        CONCAT(P.FirstName, ' ', P.LastName)
),
SalesPersonCountByTerritory AS (
    SELECT
        TerritoryName,
        COUNT(DISTINCT SalesPersonID) AS SalesPersonCount
    FROM 
        SalesPersonByTerritory
    GROUP BY 
        TerritoryName
)
SELECT
    SPT.TerritoryName,
    SPT.SalesPersonName,
    SPC.SalesPersonCount
FROM 
    SalesPersonByTerritory AS SPT
JOIN 
    SalesPersonCountByTerritory AS SPC ON SPT.TerritoryName = SPC.TerritoryName
ORDER BY 
    SPT.TerritoryName,
    SPT.SalesPersonName;

------------------------------------------------------------------------
-- 10. Who's The Lowest 2 SalesPersons
-- ~ -- Syed Abbas  In Australia 
-- ~ -- Amy Alberts In Germany 
-- ~ -- They Both Show Bad Performance And Since Australia & Germany Have Only 2 SalesPersons So It's More clear Why The Sales Is Low In Both 
WITH SalesPersonOrdersAndRevenue AS (
    SELECT 
        Soh.SalesPersonID,
        CONCAT(P.FirstName, ' ', P.LastName) AS SalesPersonName,
        COUNT(Soh.SalesOrderID) AS NumberOfOrders,
        SUM(Soh.TotalDue) AS TotalRevenue
    FROM 
        Sales.SalesOrderHeader AS Soh
    JOIN 
        Person.Person AS P ON Soh.SalesPersonID = P.BusinessEntityID
    GROUP BY 
        Soh.SalesPersonID,
        CONCAT(P.FirstName, ' ', P.LastName)
),
RankedSalesPersons AS (
    SELECT
        SalesPersonID,
        SalesPersonName,
        NumberOfOrders,
        TotalRevenue,
        RANK() OVER (ORDER BY NumberOfOrders ASC) AS OrderRank,
        RANK() OVER (ORDER BY TotalRevenue ASC) AS RevenueRank
    FROM 
        SalesPersonOrdersAndRevenue
)
SELECT 
    SalesPersonID,
    SalesPersonName,
    NumberOfOrders,
    TotalRevenue
FROM 
    RankedSalesPersons
WHERE 
    OrderRank <= 2
    OR RevenueRank <= 2
ORDER BY 
    SalesPersonID;    

------------------------------------------------------------------------
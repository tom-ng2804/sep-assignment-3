USE Northwind;

-- 1. List all cities that have both Employees and Customers.
SELECT City
FROM Employees
INTERSECT
SELECT City
FROM Customers

-- 2. List all cities that have Customers but no Employee.
-- a. Use sub-query
SELECT DISTINCT City
FROM Customers
WHERE City NOT IN (SELECT City FROM Employees)

-- b. Do not use sub-query
SELECT City
FROM Customers
EXCEPT
SELECT City
FROM Employees

-- 3. List all products and their total order quantities throughout all orders.
WITH cte(ProductID, TotalQuantity) AS (
	SELECT p.ProductID, SUM(od.Quantity) AS TotalQuantity
	FROM Products p
		JOIN [Order Details] od ON p.ProductID = od.ProductID
	GROUP BY p.ProductID
)
SELECT *
FROM Products p
	LEFT JOIN cte c ON p.ProductID = c.ProductID

-- 4. List all Customer Cities and total products ordered by that city.
SELECT c.City, COUNT(od.ProductID) AS TotalProductOrdered
FROM Customers c
	LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
	LEFT JOIN [Order Details] od ON o.OrderID = od.OrderID
GROUP BY c.City

-- 5. List all Customer Cities that have at least two customers.
-- a. Use union
WITH cte(City, CityCount) AS (
	SELECT City, COUNT(CustomerID) OVER(PARTITION BY City) AS CityCount
	FROM Customers
)
SELECT City
FROM cte
WHERE CityCount >= 2
INTERSECT
SELECT City
FROM Customers

-- b. Use sub-query and no union
SELECT DISTINCT c.City
FROM Customers c
	JOIN (
		SELECT CustomerID, COUNT(CustomerID) OVER(PARTITION BY City) AS CityCount
		FROM Customers
	) dt ON c.CustomerID = dt.CustomerID
WHERE dt.CityCount >= 2

-- 6. List all Customer Cities that have ordered at least two different kinds of products.
WITH cte(City, UniqueProductCount) AS (
	SELECT c.City, COUNT(od.ProductID) OVER(PARTITION BY od.OrderID) AS UniqueProductCount
	FROM Customers c
		LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
		LEFT JOIN [Order Details] od ON o.OrderID = od.OrderID
)
SELECT DISTINCT c.City
FROM Customers c
	JOIN cte ON c.City = cte.City
WHERE cte.UniqueProductCount >= 2

-- 7. List all Customers who have ordered products, but have the ‘ship city’ on the order different from their own customer cities.
WITH cte(CustomerID, OrderID, ShipCity) AS (
	SELECT c.CustomerID, o.OrderID, o.ShipCity
	FROM Orders o
		LEFT JOIN Customers c ON o.CustomerID = c.CustomerID
	EXCEPT
	SELECT c.CustomerID, o.OrderID, c.City
	FROM Customers c
		LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
)
SELECT *
FROM Customers
WHERE CustomerID IN (SELECT CustomerID FROM cte)

-- 8. List 5 most popular products, their average price, and the customer city that ordered most quantity of it.
WITH cte(City, ProductID, AveragePrice, QuantitySold, QuantitySoldRank) AS (
	SELECT c.City, od.ProductID, AVG(od.UnitPrice) AS AveragePrice, SUM(od.Quantity) AS QuantitySold, RANK() OVER(PARTITION BY c.City, od.ProductID ORDER BY SUM(od.Quantity) DESC) AS QuantitySoldRank
	FROM Customers c
		JOIN Orders o ON c.CustomerID = o.CustomerID
		JOIN [Order Details] od ON o.OrderID = od.OrderID
	GROUP BY c.City, od.ProductID
)
SELECT TOP 5 City, ProductID, AveragePrice, QuantitySold, QuantitySoldRank
FROM cte
WHERE QuantitySoldRank = 1
ORDER BY QuantitySold DESC

-- 9. List all cities that have never ordered something but we have employees there.
-- a. Use sub-query
SELECT City
FROM Employees
WHERE City NOT IN (SELECT ShipCity FROM Orders)

-- b. Do not use sub-query
SELECT City
FROM Employees
EXCEPT
SELECT ShipCity
FROM Orders

-- 10. List one city, if exists, that is the city from where the employee sold most orders (not the product quantity) is, and also the city of most total quantity of products ordered from. (tip: join sub-query)
SELECT City
FROM Employees
WHERE EmployeeID = (
	SELECT TOP 1 e.EmployeeID
	FROM Employees e
		JOIN Orders o ON e.EmployeeID = o.EmployeeID
	GROUP BY e.EmployeeID
	ORDER BY COUNT(o.OrderID) DESC
) AND City = (
	SELECT TOP 1 o.ShipCity
	FROM Orders o
		JOIN [Order Details] od ON o.OrderID = od.OrderID
	GROUP BY o.ShipCity
	ORDER BY SUM(od.Quantity) DESC
)

-- 11. How do you remove the duplicates record of a table?
/*
You can use the WHERE clause with the NOT IN operator to filter out the table itself as a subquery.
Or you can use a ROW_NUMBER function on a column that you want to remove the duplicates from. Records with the same value will have the same row number, so you can just filter by that.
*/

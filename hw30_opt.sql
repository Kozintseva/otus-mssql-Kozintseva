 --1. исх.скрипт
 /*
  SQL Server Execution Times:
   CPU time = 453 ms,  elapsed time = 650 ms.
 */
 
USE WideWorldImporters;
SET STATISTICS io, time on;

Select ord.CustomerID, det.StockItemID, SUM(det.UnitPrice), SUM(det.Quantity), COUNT(ord.OrderID)
FROM Sales.Orders AS ord
JOIN Sales.OrderLines AS det
ON det.OrderID = ord.OrderID
JOIN Sales.Invoices AS Inv
ON Inv.OrderID = ord.OrderID
JOIN Sales.CustomerTransactions AS Trans
ON Trans.InvoiceID = Inv.InvoiceID
JOIN Warehouse.StockItemTransactions AS ItemTrans
ON ItemTrans.StockItemID = det.StockItemID
WHERE Inv.BillToCustomerID != ord.CustomerID
AND (Select SupplierId
FROM Warehouse.StockItems AS It
Where It.StockItemID = det.StockItemID) = 12
AND (SELECT SUM(Total.UnitPrice*Total.Quantity)
FROM Sales.OrderLines AS Total
Join Sales.Orders AS ordTotal
On ordTotal.OrderID = Total.OrderID
WHERE ordTotal.CustomerID = Inv.CustomerID) > 250000
AND DATEDIFF(dd, Inv.InvoiceDate, ord.OrderDate) = 0
GROUP BY ord.CustomerID, det.StockItemID
ORDER BY ord.CustomerID,  det.StockItemID
 
 --2.оптимизированный
 /*
 SQL Server Execution Times:
   CPU time = 265 ms,  elapsed time = 391 ms.
   */

SET STATISTICS io, time on;
with
summ as (
SELECT ordTotal.CustomerID , SUM(Total.UnitPrice*Total.Quantity) as s
	FROM Sales.OrderLines AS Total
	Join Sales.Orders AS ordTotal   On ordTotal.OrderID = Total.OrderID
	group by ordTotal.CustomerID 
	having SUM(Total.UnitPrice*Total.Quantity)>250000
)

Select ord.CustomerID,det.StockItemID,  SUM(det.UnitPrice), SUM(det.Quantity), COUNT(ord.OrderID)
FROM Sales.Orders AS ord 
JOIN Sales.OrderLines AS det ON det.OrderID = ord.OrderID
JOIN Sales.Invoices AS Inv ON Inv.OrderID = ord.OrderID 
join Warehouse.StockItems it on It.StockItemID = det.StockItemID  --убрала подзапрос, перенесла в джойн
--JOIN Sales.CustomerTransactions AS Trans ON Trans.InvoiceID = Inv.InvoiceID   --не нужна, не участвует в отборе данных
JOIN Warehouse.StockItemTransactions AS ItemTrans ON ItemTrans.StockItemID = det.StockItemID 
JOIN  summ ON summ.CustomerID=Inv.CustomerID   --второй подзапрос в CTE (проверила - с джойном больше немного цпу чем в cte))
WHERE Inv.BillToCustomerID != ord.CustomerID
 and it.SupplierID=12

/*AND (Select SupplierId
	FROM Warehouse.StockItems AS It
	Where It.StockItemID = det.StockItemID) = 12*/
/*AND (SELECT SUM(Total.UnitPrice*Total.Quantity)
	FROM Sales.OrderLines AS Total
	Join Sales.Orders AS ordTotal On ordTotal.OrderID = Total.OrderID
	WHERE ordTotal.CustomerID = Inv.CustomerID) > 250000*/
	--AND DATEDIFF(dd, Inv.InvoiceDate, ord.OrderDate) = 0
AND Inv.InvoiceDate = ord.OrderDate  --равносильно прежнему условию, но без функции - для индекса
GROUP BY ord.CustomerID, det.StockItemID
ORDER BY ord.CustomerID,  det.StockItemID



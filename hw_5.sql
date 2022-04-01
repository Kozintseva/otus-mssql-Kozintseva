/*
�������� ������� �� ����� MS SQL Server Developer � OTUS.

������� "03 - ����������, CTE, ��������� �������".

������� ����������� � �������������� ���� ������ WideWorldImporters.
*/

USE WideWorldImporters

/*
1. �������� ����������� (Application.People), ������� �������� ������������ (IsSalesPerson), 
� �� ������� �� ����� ������� 04 ���� 2015 ����. 
������� �� ���������� � ��� ������ ���. 
������� �������� � ������� Sales.Invoices.
*/

TODO: 

--��������� ������
select p.PersonID as "Id ����������",
       p.FullName as "��� ����������"

from Application.People p
where p.IsSalesperson=1 and
      not exists (select 1 from Sales.Invoices i where i.InvoiceDate='2015-07-04'  and i.SalespersonPersonID=p.PersonID)

-- WITH
;
with

inv as  (  select i.SalespersonPersonID
           from Sales.Invoices i 
		   where i.InvoiceDate='2015-07-04') 

select p.PersonID as "Id ����������",
       p.FullName as "��� ����������"

from  Application.People p
left join inv on p.PersonID=inv.SalespersonPersonID
where p.IsSalesperson=1 and inv.SalespersonPersonID is NULL  --- ��� ���: and p.PersonID not in (select SalespersonPersonID from inv)



/*
2. �������� ������ � ����������� ����� (�����������). �������� ��� �������� ����������. 
�������: �� ������, ������������ ������, ����.
*/

TODO: 
--�������1
select s.StockItemID as "ID ������", 
       s.StockItemName as  "������������ ������", 
	   s.UnitPrice as "���� ������"
from Warehouse.StockItems s
where s.UnitPrice = (select min(UnitPrice) from Warehouse.StockItems);

--�������2
select s.StockItemID as "ID ������", 
       s.StockItemName as  "������������ ������", 
	   s.UnitPrice as "���� ������" 
from Warehouse.StockItems s
where s.UnitPrice = (select top 1 UnitPrice from Warehouse.StockItems order by UnitPrice asc);



/*
3. �������� ���������� �� ��������, ������� �������� �������� ���� ������������ �������� 
�� Sales.CustomerTransactions. 
����������� ��������� �������� (� ��� ����� � CTE). 
*/

TODO: 
--������� 1 (���������� ��� ����������)))

					select top 5 ct.customerid as "Id ��������", 
					            c.CustomerName as "������������" , 
	                            c.PhoneNumber as "�������"  , 
								TransactionAmount as "����� ��������"
					from Sales.CustomerTransactions ct 
					left join Sales.Customers c on ct.CustomerID=c.CustomerID
					order by ct.TransactionAmount desc
    
-- ������� 2 (� ������������, �� �� ���������� ��� �� �� ������, ������ ���� ��� ������ �������))
select top 5   ct.customerid as "Id ��������", 
			  (select  c.CustomerName from Sales.Customers c where c.CustomerID=ct.CustomerID) as "������������" , 
	          (select  c.PhoneNumber from Sales.Customers c where c.CustomerID=ct.CustomerID)  as "�������"  , 
               TransactionAmount as "����� ��������"
			   from Sales.CustomerTransactions ct 
			   order by ct.TransactionAmount desc

--������� 3
;
with
MaxTransacs  as (
                    select * from (
					select  ct.customerid, TransactionAmount, row_number () over (order by ct.TransactionAmount desc) as rn
					from Sales.CustomerTransactions ct ) ct1
					 where ct1.rn<6		
                )

select c.CustomerID as "Id ��������", 
       c.CustomerName as "������������" , 
	   c.PhoneNumber as "�������"  , 
	   m.TransactionAmount as "����� ��������"
from Sales.Customers c
inner join MaxTransacs m on c.CustomerID=m.CustomerID
order by TransactionAmount desc

/*
4. �������� ������ (�� � ��������), � ������� ���� ���������� ������, 
�������� � ������ ����� ������� �������, � ����� ��� ����������, 
������� ����������� �������� ������� (PackedByPersonID).
*/


TODO: 

select  distinct ac.CityID as "ID ������", 
                 ac.CityName as "�����",  
				 (select p.FullName from Application.People p where p.PersonID=i.PackedByPersonID) as "���������"
from Sales.InvoiceLines il  --���� �������
left join Sales.Invoices i on il.InvoiceID=i.InvoiceID
left join Sales.Customers sc on sc.CustomerID=i.CustomerID  --�� ������� ������� �� �����
left join Application.Cities ac on sc.DeliveryCityID=ac.CityID  --
where il.StockItemID in (select top 3 s.StockItemID from Warehouse.StockItems s order by s.UnitPrice desc)   --������� 3 ���-�������
order by 1

-- ---------------------------------------------------------------------------
-- ������������ �������
-- ---------------------------------------------------------------------------
-- ����� ��������� ��� � ������� ��������� ������������� �������, 
-- ��� � � ������� ��������� �����\���������. 
-- �������� ������������������ �������� ����� ����� SET STATISTICS IO, TIME ON. 
-- ���� ������� � ������� ��������, �� ����������� �� (����� � ������� ����� ��������� �����). 
-- �������� ���� ����������� �� ������ �����������. 

-- 5. ���������, ��� ������ � ������������� ������

SELECT 
	Invoices.InvoiceID, 
	Invoices.InvoiceDate,
	(SELECT People.FullName
		FROM Application.People
		WHERE People.PersonID = Invoices.SalespersonPersonID
	) AS SalesPersonName,
	SalesTotals.TotalSumm AS TotalSummByInvoice, 
	(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
		FROM Sales.OrderLines
		WHERE OrderLines.OrderId = (SELECT Orders.OrderId 
			FROM Sales.Orders
			WHERE Orders.PickingCompletedWhen IS NOT NULL	
				AND Orders.OrderId = Invoices.OrderId)	
	) AS TotalSummForPickedItems
FROM Sales.Invoices 
	JOIN
	(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
		ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC

-- --

TODO: �������� ����� ���� �������

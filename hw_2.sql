

USE WideWorldImporters

/*
1. ��� ������, � �������� ������� ���� "urgent" ��� �������� ���������� � "Animal".
�������: �� ������ (StockItemID), ������������ ������ (StockItemName).
�������: Warehouse.StockItems.
*/

TODO: 
select si.StockItemID, si.StockItemName
from Warehouse.StockItems si
where lower(si.StockItemName) like '%urgent%' OR si.StockItemName like 'Animal%'


/*
2. ����������� (Suppliers), � ������� �� ���� ������� �� ������ ������ (PurchaseOrders).
������� ����� JOIN, � ����������� ������� ������� �� �����.
�������: �� ���������� (SupplierID), ������������ ���������� (SupplierName).
�������: Purchasing.Suppliers, Purchasing.PurchaseOrders.
�� ����� �������� ������ JOIN ��������� ��������������.
*/

TODO: 
select s.SupplierID, s.SupplierName
from Purchasing.Suppliers s
left join Purchasing.PurchaseOrders po on s.SupplierID=po.SupplierID
where po.SupplierID is NULL


/*
3. ������ (Orders) � ����� ������ (UnitPrice) ����� 100$ 
���� ����������� ������ (Quantity) ������ ����� 20 ����
� �������������� ����� ������������ ����� ������ (PickingCompletedWhen).
�������:
* OrderID
* ���� ������ (OrderDate) � ������� ��.��.����
* �������� ������, � ������� ��� ������ �����
* ����� ��������, � ������� ��� ������ �����
* ����� ����, � ������� ��������� ���� ������ (������ ����� �� 4 ������)
* ��� ��������� (Customer)
�������� ������� ����� ������� � ������������ ��������,
��������� ������ 1000 � ��������� ��������� 100 �������.

���������� ������ ���� �� ������ ��������, ����� ����, ���� ������ (����� �� �����������).

�������: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/
select top 100 * from Sales.Orders where OrderID=729
select * from Sales.OrderLines where OrderID=729
TODO: 

select   o.OrderID,  
         ol.OrderLineId,
         CONVERT(NVARCHAR, o.OrderDate, 104) as OrderDate, 
		 DATENAME (month,o.OrderDate) as Month_name, 
		 DATEPART(quarter, o.OrderDate) as NQuarter,
         case when datepart(month, o.OrderDate) between 1 and 4 then 1 
              when datepart(month, o.OrderDate) between 5 and 8 then 2
              when datepart(month, o.OrderDate) between 9 and 12 then 3 end as ThirdYear, 
         c.CustomerName

from Sales.Orders o
left join Sales.OrderLines ol on o.OrderID=ol.OrderID
left join Sales.Customers c on o.CustomerID=c.CustomerID
where (ol.UnitPrice>100 OR ol.Quantity>20 ) AND (o.PickingCompletedWhen is not NULL)
order by NQuarter, ThirdYear, o.OrderDate

--������� ����� ������� � ������������ ��������, ��������� ������ 1000 � ��������� ��������� 100 �������.
select   o.OrderID,  
         ol.OrderLineID,
         CONVERT(NVARCHAR, o.OrderDate, 104) as OrderDate, 
		 DATENAME (month,o.OrderDate) as Month_name, 
		 DATEPART(quarter, o.OrderDate) as NQuarter,
         case when datepart(month, o.OrderDate) between 1 and 4 then 1 
              when datepart(month, o.OrderDate) between 5 and 8 then 2
              when datepart(month, o.OrderDate) between 9 and 12 then 3 end as ThirdYear, 
         c.CustomerName

from Sales.Orders o
left join Sales.OrderLines ol on o.OrderID=ol.OrderID
left join Sales.Customers c on o.CustomerID=c.CustomerID
where (ol.UnitPrice>100 OR ol.Quantity>20 ) AND (o.PickingCompletedWhen is not NULL)
order by NQuarter, ThirdYear, o.OrderDate
OFFSET 1000 ROWS FETCH FIRST 100 ROWS ONLY;  --���������� 1000 ����� � ������� ����. 100


/*
4. ������ ����������� (Purchasing.Suppliers),
������� ������ ���� ��������� (ExpectedDeliveryDate) � ������ 2013 ����
� ��������� "Air Freight" ��� "Refrigerated Air Freight" (DeliveryMethodName)
� ������� ��������� (IsOrderFinalized).
�������:
* ������ �������� (DeliveryMethodName)
* ���� �������� (ExpectedDeliveryDate)
* ��� ����������
* ��� ����������� ���� ������������ ����� (ContactPerson)

�������: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

TODO: 


select po.PurchaseOrderID as "ID ������", po.ExpectedDeliveryDate as "���� ��������", po.DeliveryMethodID, dm.DeliveryMethodName,s.SupplierName as "��� ����������", p.FullName as "���������� ����"
from Purchasing.PurchaseOrders po
left join Purchasing.Suppliers s on po.SupplierID=s.SupplierID
left join Application.DeliveryMethods dm on po.DeliveryMethodID=dm.DeliveryMethodID
left join Application.People p on po.ContactPersonID=p.PersonID
where po.ExpectedDeliveryDate between '2013-01-01' and '2013-01-31'
and dm.DeliveryMethodName in ('Air Freight','Refrigerated Air Freight')
and po.IsOrderFinalized=1

/*
5. ������ ��������� ������ (�� ���� �������) � ������ ������� � ������ ����������,
������� ������� ����� (SalespersonPerson).
������� ��� �����������.
*/

TODO: 
select top 10 o.OrderID, o.OrderDate, o.CustomerID, c.CustomerName as Client, o.SalespersonPersonID, ap.FullName as SotrDate 
from  Sales.Orders o
left join Sales.Customers c on o.CustomerID=c.CustomerID
left join Application.People ap on o.SalespersonPersonID=ap.PersonID
order by o.OrderDate desc


/*
6. ��� �� � ����� �������� � �� ���������� ��������,
������� �������� ����� "Chocolate frogs 250g".
��� ������ �������� � ������� Warehouse.StockItems.
*/

TODO: 

with
purchase as ( --��� ������� Chocolate frogs 250g
             select o.OrderID, o.CustomerID, ol.StockItemID
			 from Sales.Orders o
			 left join Sales.OrderLines ol on o.OrderID=ol.OrderID
			 where ol.StockItemID=(select si.StockItemId from  Warehouse.StockItems si where si.StockItemName='Chocolate frogs 250g')
            )

select c.CustomerID as "Id �������", c.CustomerName as "��� �������", c.PhoneNumber as "���������� �����", c.FaxNumber as "����"
from Sales.Customers c
where exists (select 1 from purchase p where p.CustomerID=c.CustomerID)
order by c.CustomerName
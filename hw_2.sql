

USE WideWorldImporters

/*
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

TODO: 
select si.StockItemID, si.StockItemName
from Warehouse.StockItems si
where lower(si.StockItemName) like '%urgent%' OR si.StockItemName like 'Animal%'


/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

TODO: 
select s.SupplierID, s.SupplierName
from Purchasing.Suppliers s
left join Purchasing.PurchaseOrders po on s.SupplierID=po.SupplierID
where po.SupplierID is NULL


/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
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

--вариант этого запроса с постраничной выборкой, пропустив первую 1000 и отобразив следующие 100 записей.
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
OFFSET 1000 ROWS FETCH FIRST 100 ROWS ONLY;  --пропустить 1000 строк и вывести след. 100


/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

TODO: 


select po.PurchaseOrderID as "ID заказа", po.ExpectedDeliveryDate as "Дата доставки", po.DeliveryMethodID, dm.DeliveryMethodName,s.SupplierName as "Имя поставщика", p.FullName as "Контактное лицо"
from Purchasing.PurchaseOrders po
left join Purchasing.Suppliers s on po.SupplierID=s.SupplierID
left join Application.DeliveryMethods dm on po.DeliveryMethodID=dm.DeliveryMethodID
left join Application.People p on po.ContactPersonID=p.PersonID
where po.ExpectedDeliveryDate between '2013-01-01' and '2013-01-31'
and dm.DeliveryMethodName in ('Air Freight','Refrigerated Air Freight')
and po.IsOrderFinalized=1

/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/

TODO: 
select top 10 o.OrderID, o.OrderDate, o.CustomerID, c.CustomerName as Client, o.SalespersonPersonID, ap.FullName as SotrDate 
from  Sales.Orders o
left join Sales.Customers c on o.CustomerID=c.CustomerID
left join Application.People ap on o.SalespersonPersonID=ap.PersonID
order by o.OrderDate desc


/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

TODO: 

with
purchase as ( --все покупки Chocolate frogs 250g
             select o.OrderID, o.CustomerID, ol.StockItemID
			 from Sales.Orders o
			 left join Sales.OrderLines ol on o.OrderID=ol.OrderID
			 where ol.StockItemID=(select si.StockItemId from  Warehouse.StockItems si where si.StockItemName='Chocolate frogs 250g')
            )

select c.CustomerID as "Id клиента", c.CustomerName as "Имя клиента", c.PhoneNumber as "Контактный номер", c.FaxNumber as "Факс"
from Sales.Customers c
where exists (select 1 from purchase p where p.CustomerID=c.CustomerID)
order by c.CustomerName
/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "03 - Подзапросы, CTE, временные таблицы".

Задания выполняются с использованием базы данных WideWorldImporters.
*/

USE WideWorldImporters

/*
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. 
Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices.
*/

TODO: 

--вложенный запрос
select p.PersonID as "Id сотрудника",
       p.FullName as "ФИО сотрудника"

from Application.People p
where p.IsSalesperson=1 and
      not exists (select 1 from Sales.Invoices i where i.InvoiceDate='2015-07-04'  and i.SalespersonPersonID=p.PersonID)

-- WITH
;
with

inv as  (  select i.SalespersonPersonID
           from Sales.Invoices i 
		   where i.InvoiceDate='2015-07-04') 

select p.PersonID as "Id сотрудника",
       p.FullName as "ФИО сотрудника"

from  Application.People p
left join inv on p.PersonID=inv.SalespersonPersonID
where p.IsSalesperson=1 and inv.SalespersonPersonID is NULL  --- или так: and p.PersonID not in (select SalespersonPersonID from inv)



/*
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.
*/

TODO: 
--вариант1
select s.StockItemID as "ID товара", 
       s.StockItemName as  "Наименование товара", 
	   s.UnitPrice as "Цена товара"
from Warehouse.StockItems s
where s.UnitPrice = (select min(UnitPrice) from Warehouse.StockItems);

--вариант2
select s.StockItemID as "ID товара", 
       s.StockItemName as  "Наименование товара", 
	   s.UnitPrice as "Цена товара" 
from Warehouse.StockItems s
where s.UnitPrice = (select top 1 UnitPrice from Warehouse.StockItems order by UnitPrice asc);



/*
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей 
из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE). 
*/

TODO: 
--вариант 1 (получилось без подзапроса)))

					select top 5 ct.customerid as "Id компании", 
					            c.CustomerName as "Наименование" , 
	                            c.PhoneNumber as "Телефон"  , 
								TransactionAmount as "Сумма перевода"
					from Sales.CustomerTransactions ct 
					left join Sales.Customers c on ct.CustomerID=c.CustomerID
					order by ct.TransactionAmount desc
    
-- вариант 2 (с подзапросами, но на продакшене так бы не делала, только если это разные таблицы))
select top 5   ct.customerid as "Id компании", 
			  (select  c.CustomerName from Sales.Customers c where c.CustomerID=ct.CustomerID) as "Наименование" , 
	          (select  c.PhoneNumber from Sales.Customers c where c.CustomerID=ct.CustomerID)  as "Телефон"  , 
               TransactionAmount as "Сумма перевода"
			   from Sales.CustomerTransactions ct 
			   order by ct.TransactionAmount desc

--вариант 3
;
with
MaxTransacs  as (
                    select * from (
					select  ct.customerid, TransactionAmount, row_number () over (order by ct.TransactionAmount desc) as rn
					from Sales.CustomerTransactions ct ) ct1
					 where ct1.rn<6		
                )

select c.CustomerID as "Id компании", 
       c.CustomerName as "Наименование" , 
	   c.PhoneNumber as "Телефон"  , 
	   m.TransactionAmount as "Сумма перевода"
from Sales.Customers c
inner join MaxTransacs m on c.CustomerID=m.CustomerID
order by TransactionAmount desc

/*
4. Выберите города (ид и название), в которые были доставлены товары, 
входящие в тройку самых дорогих товаров, а также имя сотрудника, 
который осуществлял упаковку заказов (PackedByPersonID).
*/


TODO: 

select  distinct ac.CityID as "ID города", 
                 ac.CityName as "Город",  
				 (select p.FullName from Application.People p where p.PersonID=i.PackedByPersonID) as "Упаковщик"
from Sales.InvoiceLines il  --ищем продажи
left join Sales.Invoices i on il.InvoiceID=i.InvoiceID
left join Sales.Customers sc on sc.CustomerID=i.CustomerID  --по клиенту выходим на город
left join Application.Cities ac on sc.DeliveryCityID=ac.CityID  --
where il.StockItemID in (select top 3 s.StockItemID from Warehouse.StockItems s order by s.UnitPrice desc)   --условие 3 топ-товаров
order by 1

-- ---------------------------------------------------------------------------
-- Опциональное задание
-- ---------------------------------------------------------------------------
-- Можно двигаться как в сторону улучшения читабельности запроса, 
-- так и в сторону упрощения плана\ускорения. 
-- Сравнить производительность запросов можно через SET STATISTICS IO, TIME ON. 
-- Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы). 
-- Напишите ваши рассуждения по поводу оптимизации. 

-- 5. Объясните, что делает и оптимизируйте запрос

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

TODO: напишите здесь свое решение

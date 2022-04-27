/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "05 - Операторы CROSS APPLY, PIVOT, UNPIVOT".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Клиентов взять с ID 2-6, это все подразделение Tailspin Toys.
Имя клиента нужно поменять так чтобы осталось только уточнение.
Например, исходное значение "Tailspin Toys (Gasport, NY)" - вы выводите только "Gasport, NY".
Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+-------------+--------------+------------
InvoiceMonth | Peeples Valley, AZ | Medicine Lodge, KS | Gasport, NY | Sylvanite, MT | Jessie, ND
-------------+--------------------+--------------------+-------------+--------------+------------
01.01.2013   |      3             |        1           |      4      |      2        |     2
01.02.2013   |      7             |        3           |      4      |      2        |     1
-------------+--------------------+--------------------+-------------+--------------+------------
*/


SELECT InvoiceMonth, --значения это заголовки строк
       [Tailspin Toys (Sylvanite, MT)] as "Sylvanite, MT" ,
	   [Tailspin Toys (Peeples Valley, AZ)] as "Peeples Valley, A",
	   [Tailspin Toys (Medicine Lodge, KS)] as "Medicine Lodge, KS",
	   [Tailspin Toys (Gasport, NY)] as "Gasport, NY",
	   [Tailspin Toys (Jessie, ND)] as "Jessie, ND"         --значения из столбца в type, это заголовки столбцов

FROM
(
      SELECT   CONVERT(NVARCHAR, DATEFROMPARTS(year(i.InvoiceDate),month(i.InvoiceDate),1), 104) as InvoiceMonth,
               (select c.CustomerName from Sales.Customers c where c.CustomerID=i.CustomerID) as CustomerName
      FROM     Sales.Invoices i
      WHERE    i.CustomerID  between 2 and 6
) pt
PIVOT 
(
   count (CustomerName) 
   FOR   CustomerName  --type
   --конкретные значения в столбце type
   IN   ( [Tailspin Toys (Sylvanite, MT)],[Tailspin Toys (Peeples Valley, AZ)],[Tailspin Toys (Medicine Lodge, KS)],[Tailspin Toys (Gasport, NY)],[Tailspin Toys (Jessie, ND)])
) as pvt

order by InvoiceMonth

/*
2. Для всех клиентов с именем, в котором есть "Tailspin Toys"
вывести все адреса, которые есть в таблице, в одной колонке.

Пример результата:
----------------------------+--------------------
CustomerName                | AddressLine
----------------------------+--------------------
Tailspin Toys (Head Office) | Shop 38
Tailspin Toys (Head Office) | 1877 Mittal Road
Tailspin Toys (Head Office) | PO Box 8975
Tailspin Toys (Head Office) | Ribeiroville
----------------------------+--------------------
*/

SELECT * FROM (
               SELECT c.CustomerID, c.CustomerName, c.DeliveryAddressLine1,c.DeliveryAddressLine2, c.PostalAddressLine1, c.PostalAddressLine2  
			   FROM Sales.Customers c
               WHERE c.CustomerName like '%Tailspin Toys%' ) as dt
UNPIVOT ( AddreddLine FOR NameAddress  --названия столбцов
IN (DeliveryAddressLine1,DeliveryAddressLine2, PostalAddressLine1, PostalAddressLine2)) as unpvt   --что собираем
ORDER BY CustomerID

/*
3. В таблице стран (Application.Countries) есть поля с цифровым кодом страны и с буквенным.
Сделайте выборку ИД страны, названия и ее кода так, 
чтобы в поле с кодом был либо цифровой либо буквенный код.

Пример результата:
--------------------------------
CountryId | CountryName | Code
----------+-------------+-------
1         | Afghanistan | AFG
1         | Afghanistan | 4
3         | Albania     | ALB
3         | Albania     | 8
----------+-------------+-------
*/


SELECT * FROM (
                 SELECT c.CountryID, c.CountryName, c.IsoAlpha3Code, cast (c.IsoNumericCode as nvarchar(3)) as IsoNumericCode 
				 FROM   Application.Countries c ) as dt
UNPIVOT ( Code FOR Typed
IN (IsoAlpha3Code, IsoNumericCode) )  as unpvt



/*
4. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

SELECT			c.CustomerID as "Id покупателя",
				c.CustomerName as "Покупатель",
				cr.StockItemID as "Id товара",
				cr.UnitPrice as "Сумма товара",
				cr.InvoiceDate as "Дата заказа"

FROM			Sales.Customers C
CROSS APPLY     (SELECT  TOP 2 
						i.CustomerID, 
					   (select c.CustomerName from Sales.Customers c where c.CustomerID=i.CustomerID) as CustomerName,
						il.StockItemID, 
						il.UnitPrice,
						i.InvoiceDate
				
				  FROM      Sales.Invoices i
				  LEFT JOIN Sales.InvoiceLines il on i.invoiceId=il.InvoiceID
				  WHERE i.CustomerID = C.CustomerID
				  ORDER BY il.UnitPrice DESC ) as CR

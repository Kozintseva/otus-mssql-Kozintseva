/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "06 - Оконные функции".

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
1. Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года 
(в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки).
Выведите: id продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом

Пример:
-------------+----------------------------
Дата продажи | Нарастающий итог по месяцу
-------------+----------------------------
 2015-01-29   | 4801725.31
 2015-01-30	 | 4801725.31
 2015-01-31	 | 4801725.31
 2015-02-01	 | 9626342.98
 2015-02-02	 | 9626342.98
 2015-02-03	 | 9626342.98
Продажи можно взять из таблицы Invoices.
Нарастающий итог должен быть без оконной функции.
*/

--SQL Server Execution Times: CPU time = 454 ms,  elapsed time = 776 ms.
--без оконной функции - плохо читаемый )). Если запрос будет сложнее, то можно в конец запутаться. С окном - визуально более понятно)

set statistics time, io on
go
with
tbl as --считаем сумму каждой продажи
(
                select distinct i.InvoiceID as InvoiceID,i.CustomerID, i.InvoiceDate,
                SUM(il.UnitPrice*il.Quantity) OVER(partition by i.InvoiceID ORDER BY i.InvoiceDate) as InvoiceSumma   ---считаем сумму каждой продажи
                from Sales.Invoices i
                left join Sales.InvoiceLines il on i.InvoiceID=il.InvoiceID
                where i.InvoiceDate  >= '2015-01-01'
	) 

	select  year(t1.InvoiceDate) as "Год", month(t1.InvoiceDate) as "Месяц", t1.InvoiceDate as "Дата продажи", 
	        t1.InvoiceID as "Id продажи", 
			t1.CustomerID as "Id покупателя", 
			sum(t2.InvoiceSumma) as "Нарастающий итог по месяцам"	
	from tbl t1
	inner join tbl t2 on year(t2.InvoiceDate)=year(t1.InvoiceDate) and  month(t2.InvoiceDate)<=month(t1.InvoiceDate)
	group by year(t1.InvoiceDate), month(t1.InvoiceDate), t1.InvoiceDate, t1.InvoiceID, t1.CustomerID
    order by t1.InvoiceDate
set statistics time, io off
go

/*
2. Сделайте расчет суммы нарастающим итогом в предыдущем запросе с помощью оконной функции.
   Сравните производительность запросов 1 и 2 с помощью set statistics time, io on
*/

-- SQL Server Execution Times: CPU time = 203 ms,  elapsed time = 788 ms.
set statistics time, io on
go
select tbl.InvoiceID as "Id продажи", 
       tbl.CustomerID as "Id покупателя", 
	  (select c.CustomerName from Sales.Customers c where c.CustomerID=tbl.CustomerID) as "Покупатель",
	   tbl.InvoiceDate as "Дата продажи",
	   tbl.InvoiceSumma as "Сумма продажи",
	 
       SUM(tbl.InvoiceSumma) OVER(ORDER BY year(tbl.InvoiceDate), month(tbl.InvoiceDate)) as "Нарастающий итог по месяцам"  --сумма по месяцам
from (
                select distinct i.InvoiceID,i.CustomerID, i.InvoiceDate,
                SUM(il.UnitPrice*il.Quantity) OVER(partition by i.InvoiceID ORDER BY i.InvoiceDate) as InvoiceSumma   ---считаем сумму каждой продажи
                from Sales.Invoices i
                left join Sales.InvoiceLines il on i.InvoiceID=il.InvoiceID
                where i.InvoiceDate  >= '2015-01-01'
	) tbl

order by tbl.InvoiceDate 
set statistics time, io off


/*
3. Вывести список 2х самых популярных продуктов (по количеству проданных) 
в каждом месяце за 2016 год (по 2 самых популярных продукта в каждом месяце).
*/ 

select    
         tbl.dyear as "год продажи",
		 tbl.dmonth as "месяц продажи",
         tbl.Description as "товар",
		 tbl.allcount as "Количество проданного товара"
from (
         select year(i.InvoiceDate) as dyear, month(i.InvoiceDate) as dmonth, il.Description,  
		 sum(Quantity) as allcount, --всего продано каждого товара
         row_number()over (partition by year(i.InvoiceDate) , month(i.InvoiceDate) order by sum(Quantity) desc) as rn  --нумеруем в порядке убывания количества
         from Sales.Invoices i 
         left join Sales.InvoiceLines il on i.InvoiceID=il.InvoiceID
         where i.InvoiceDate  >= '2016-01-01'
         group by year(i.InvoiceDate), month(i.InvoiceDate),  il.Description
) tbl
where rn in (1,2)   ---на 1 и 2 месте
order by tbl.dyear, tbl.dmonth

/*
4. Функции одним запросом
Посчитайте по таблице товаров (в вывод также должен попасть ид товара, название, брэнд и цена):
* пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
* посчитайте общее количество товаров и выведете полем в этом же запросе
* посчитайте общее количество товаров в зависимости от первой буквы названия товара
* отобразите следующий id товара исходя из того, что порядок отображения товаров по имени 
* предыдущий ид товара с тем же порядком отображения (по имени)
* названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
* сформируйте 30 групп товаров по полю вес товара на 1 шт

Для этой задачи НЕ нужно писать аналог без аналитических функций.
*/

select si.StockItemID, si.StockItemName, si.Brand, si.UnitPrice,
row_number() over( partition by substring (si.StockItemName, 1,1) order by si.StockItemName) as "rn по алфавиту",
count(si.StockItemID) over()  as "общее  число товаров",
count(*) over( partition by substring (si.StockItemName, 1,1) order by substring (si.StockItemName, 1,1))  as "число товаров на букву",
lead(si.StockItemID) over( order by si.StockItemName) as  "следующий Id товара",
lag(si.StockItemID) over( order by si.StockItemName) as  "предыдущий Id товара",
lag(si.StockItemName, 2,'No items') over( order by si.StockItemName ) as  " 2 предыдущий название товара",
ntile(30) over(order by si.TypicalWeightPerUnit) as "группа товаров по полю вес"
from Warehouse.StockItems si
order by si.StockItemName



/*
5. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал.
   В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки.
*/


                    select 
					        SalespersonPersonID as  "Id сотрудника",
							SalespersonPersonName as "ФИО сотрудника",
							CustomerID as "Id покупателя",
							CustomerName as "Покупатель",
							InvoiceID as  "Номер заказа",
							InvoiceDate as "Дата заказа",
							InvoiceSumma as "Сумма заказа",
                            TransactionAmount as "Сумма оплаты"
					from        (
                                   select    i.SalespersonPersonID as SalespersonPersonID, 
								             (select p.FullName from Application.People p where p.PersonID=i.SalespersonPersonID) as SalespersonPersonName,
											 i.CustomerID as CustomerID,
											 (select c.CustomerName from Sales.Customers c where c.CustomerID=i.CustomerID) as CustomerName,
											 i.InvoiceID as InvoiceID, 
											 i.InvoiceDate as InvoiceDate, 
								             sum(il.Quantity*il.UnitPrice) over (partition by il.InvoiceID order by il.InvoiceID) as InvoiceSumma,  ---сумма заказа
											 t.TransactionAmount as TransactionAmount ,
                                             row_number() over (partition by i.SalespersonPersonID order by i.InvoiceDate desc) as rn  --нумеруем заказы по дате убыв.
                                   from      Sales.Invoices i
								   left join Sales.InvoiceLines il on i.invoiceId=il.InvoiceID
								   left join Sales.CustomerTransactions t on i.InvoiceID=t.InvoiceID
								   
								   )z
                    where z.rn=1     ---условие отбора последнего заказа в разрезе продавцов


/*
6. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

select 
       CustomerID as "Id покупателя",
	   CustomerName as "Покупатель",
	   StockItemID as "Id товара",
	   UnitPrice as "Сумма товара",
	   InvoiceDate as "Дата заказа",
	   rnk
from       (
               select 
						i.CustomerID, 
					   (select c.CustomerName from Sales.Customers c where c.CustomerID=i.CustomerID) as CustomerName,
						il.StockItemID, 
						il.UnitPrice,
						i.InvoiceDate,
						ROW_NUMBER() over (partition by i.CustomerID order by  il.UnitPrice desc) as rn,
						DENSE_RANK() over (partition by i.CustomerID order by  il.UnitPrice desc) as rnk  --т.к.по несколько покупок, то DENSE_RANK, а не ROW_NUMBER
	 
				from      Sales.Invoices i
				left join Sales.InvoiceLines il on i.invoiceId=il.InvoiceID 
				
                   ) z
where rnk in (1,2)   ---2 самых дорогих товара



Опционально можете для каждого запроса без оконных функций сделать вариант запросов с оконными функциями и сравнить их производительность. 
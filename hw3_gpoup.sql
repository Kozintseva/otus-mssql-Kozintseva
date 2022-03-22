/*
1. Посчитать среднюю цену товара, общую сумму продажи по месяцам
Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Средняя цена за месяц по всем товарам
* Общая сумма продаж за месяц

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

--не поняла по каким колонкам считать - сделала по ExtendedPrice
select year(i.InvoiceDate) as "Год продажи", month(i.InvoiceDate) as "месяц продажи" , avg( il.UnitPrice) as "средняя цена", sum(il.UnitPrice*il.Quantity) as "сумма продажи"
from Sales.Invoices i 
left join Sales.InvoiceLines il on i.InvoiceID=il.InvoiceID
group by year(i.InvoiceDate), month(i.InvoiceDate)
order by year(i.InvoiceDate), month(i.InvoiceDate)

/*
2. Отобразить все месяцы, где общая сумма продаж превысила 10 000

Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Общая сумма продаж

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

TODO: 
select year(i.InvoiceDate) as "Год продажи", month(i.InvoiceDate) as "месяц продажи" ,  sum(il.UnitPrice*il.Quantity) as "сумма продажи"
from Sales.Invoices i 
left join Sales.InvoiceLines il on i.InvoiceID=il.InvoiceID
group by year(i.InvoiceDate), month(i.InvoiceDate)
having sum(il.UnitPrice*il.Quantity) >10000   ---сумма продаж > 10000
order by year(i.InvoiceDate), month(i.InvoiceDate)



/*
3. Вывести сумму продаж, дату первой продажи
и количество проданного по месяцам, по товарам,
продажи которых менее 50 ед в месяц.
Группировка должна быть по году,  месяцу, товару.

Вывести:
* Год продажи
* Месяц продажи
* Наименование товара
* Сумма продаж
* Дата первой продажи
* Количество проданного

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

TODO: 

select year(i.InvoiceDate) as "Год продажи", month(i.InvoiceDate) as "месяц продажи", il.Description as "товар",  min(i.InvoiceDate) as "дата первой продажи", sum(il.UnitPrice*il.Quantity) as "сумма продаж", sum(Quantity) as "количество проданного"
from Sales.Invoices i 
left join Sales.InvoiceLines il on i.InvoiceID=il.InvoiceID
group by year(i.InvoiceDate), month(i.InvoiceDate),  il.Description
having sum(Quantity)<50
order by year(i.InvoiceDate), month(i.InvoiceDate)


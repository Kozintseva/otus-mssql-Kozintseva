/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "07 - Динамический SQL".

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

Это задание из занятия "Операторы CROSS APPLY, PIVOT, UNPIVOT."
Нужно для него написать динамический PIVOT, отображающий результаты по всем клиентам.
Имя клиента указывать полностью из поля CustomerName.

Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+----------------+----------------------
InvoiceMonth | Aakriti Byrraju    | Abel Spirlea       | Abel Tatarescu | ... (другие клиенты)
-------------+--------------------+--------------------+----------------+----------------------
01.01.2013   |      3             |        1           |      4         | ...
01.02.2013   |      7             |        3           |      4         | ...
-------------+--------------------+--------------------+----------------+----------------------
*/

DECLARE @pvt as NVARCHAR(MAX)           --объявляем переменную для запроса
DECLARE @ColumnName AS NVARCHAR(MAX)    --объявляем переменную для строки колонок 

SELECT @ColumnName= ISNULL(@ColumnName + ',', '') + QUOTENAME(CustomerName)  --колонки для pivot через ','
FROM ( SELECT   distinct              --все клиенты из покупок
               (select c.CustomerName from Sales.Customers c where c.CustomerID=i.CustomerID) as CustomerName
      FROM     Sales.Invoices i
     ) as cust

SELECT @ColumnName as ColumnName   --выводим столбцы

--инициализ. переменную @pvt - это бужет наш запрос и передаем в запросе переменную @ColumnName вместо вручную перечисляения столбцов
SET @pvt = N' SELECT InvoiceMonth,
           '+ @ColumnName +'
           FROM
(
      SELECT   CONVERT(NVARCHAR, DATEFROMPARTS(year(i.InvoiceDate),month(i.InvoiceDate),1), 104) as InvoiceMonth,
               (select c.CustomerName from Sales.Customers c where c.CustomerID=i.CustomerID) as CustomerName
      FROM     Sales.Invoices i
     
) pt
PIVOT 
(
   count (CustomerName) 
   FOR   CustomerName  
   
   IN (' + @ColumnName + ')) as pvt
order by InvoiceMonth
'
select @pvt as pvt;   --выводим запрос, как будет выглядеть

EXEC sp_executesql @pvt;

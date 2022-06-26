/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "12 - Хранимые процедуры, функции, триггеры, курсоры".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

USE WideWorldImporters

/*
Во всех заданиях написать хранимую процедуру / функцию и продемонстрировать ее использование.
*/

/*
1) Написать функцию возвращающую Клиента с наибольшей суммой покупки.
*/
                                

USE WideWorldImporters
/
CREATE  OR ALTER FUNCTION myschema.IsCustomerIDMax  () 
RETURNS int     
AS    
BEGIN   --начало тела функции
DECLARE @ID int --объявляем переменную
--в  переменную передаю ID  клиента с мах покупкой
    select   top 1 @ID = i.CustomerID 
										
									   from      Sales.Invoices i
								   left join Sales.InvoiceLines il on i.invoiceId=il.InvoiceID
                                    order by sum(il.Quantity*il.UnitPrice) over (partition by il.InvoiceID order by il.InvoiceID)  desc;
     RETURN(@ID);  --возвращаем это значение
END;  
GO 
--вызов функции
select myschema.IsCustomerIDMax() as CustomerID;


/*
2) Написать хранимую процедуру с входящим параметром СustomerID, выводящую сумму покупки по этому клиенту.
Использовать таблицы :
Sales.Customers
Sales.Invoices
Sales.InvoiceLines
*/

CREATE OR ALTER PROCEDURE myschema.usp_IsMaxInvoice
	@СustomerID int 

AS
  select   max(SummaInvoice) as MaxSumma from (
	select  i.CustomerID , sum(il.Quantity*il.UnitPrice) over (partition by il.InvoiceID order by il.InvoiceID) as SummaInvoice
										
									   from      Sales.Invoices i
								   left join Sales.InvoiceLines il on i.invoiceId=il.InvoiceID) z
								   group by CustomerID
          having CustomerID=@СustomerID;

		  
GO
--вызов

exec myschema.usp_IsMaxInvoice @СustomerID= 834 ;

/*
3) Создать одинаковую функцию и хранимую процедуру, посмотреть в чем разница в производительности и почему.
*/
--является ли клиент сотрудником
--процедура
CREATE OR ALTER PROCEDURE myschema.usp_IsSalesPerson
	@СustomerName nvarchar (50)
	

AS
    DECLARE @IsFlag nvarchar (50) 
  SELECT 
  
  case when  p.IsSalesperson=1 then concat(@СustomerName, N'  - сотрудник' )
       when  p.IsSalesperson=0 then concat(@СustomerName, N'  - клиент' ) end as 'isFlag'
	
FROM Application.People p
where p.FullName=@СustomerName

GO


--функция
CREATE  OR ALTER FUNCTION myschema.ufn_IsSalesPerson  (@СustomerName nvarchar (50)) 
RETURNS nvarchar (50)   
AS    
BEGIN   
  DECLARE @IsFlag nvarchar (50) 
  SELECT  @IsFlag = (case when  p.IsSalesperson=1 then concat(@СustomerName, N'  - сотрудник' )
              when  p.IsSalesperson=0 then concat(@СustomerName, N'  - клиент' ) end  )
	
FROM Application.People p
where p.FullName=@СustomerName
return ( @IsFlag);
END;  
GO 

--вызов . Судя по плану функция пошустрее будет. Но пока не понимаю почему так ))
--скрин плана https://github.com/Kozintseva/otus-mssql-Kozintseva/blob/main/hw18_3.png


exec   myschema.usp_IsSalesPerson  'Kayla Woodcock'   ;
select myschema.ufn_IsSalesPerson ('Kayla Woodcock')  ;

/*
4) Создайте табличную функцию покажите как ее можно вызвать для каждой строки result set'а без использования цикла. 
*/
--табличная функция, выводит все города, куда был отправлен товар

CREATE FUNCTION myschema.ufn_ListTown (@StockName varchar(50))  
RETURNS TABLE  
AS  
RETURN   
(  
   select  distinct ac.CityID as 'Id town', 
                 ac.CityName as 'Town' 
				
from Sales.InvoiceLines il  
left join Sales.Invoices i on il.InvoiceID=i.InvoiceID
left join Sales.Customers sc on sc.CustomerID=i.CustomerID 
left join Application.Cities ac on sc.DeliveryCityID=ac.CityID  
where il.Description =  @StockName 
);  
GO  
-- вызов фукнкции
select * from myschema.ufn_ListTown ('Plush shark slippers (Gray) L');

--вторую часть вопроса не поняла, та которая "как ее можно вызвать для каждой строки result set'а без использования цикла"
/*
5) Опционально. Во всех процедурах укажите какой уровень изоляции транзакций вы бы использовали и почему. 
*/

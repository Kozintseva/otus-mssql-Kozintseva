/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "10 - Операторы изменения данных".

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
1. Довставлять в базу пять записей используя insert в таблицу Customers или Suppliers 
*/
select convert(date,getdate())
select * from Sales.Customers
select * from Application.People where PersonID=1001
select * from Application.DeliveryMethods
select * from Application.Cities

INSERT INTO [Sales].[Customers]
           ([CustomerID],[CustomerName],[BillToCustomerID],[CustomerCategoryID],[PrimaryContactPersonID],[AlternateContactPersonID],[DeliveryMethodID],[DeliveryCityID],[PostalCityID],[CreditLimit],[AccountOpenedDate],[StandardDiscountPercentage],[IsStatementSent],[IsOnCreditHold],[PaymentDays],[PhoneNumber],[FaxNumber],[WebsiteURL],[DeliveryAddressLine1],[DeliveryPostalCode],[PostalAddressLine1],[PostalPostalCode],[LastEditedBy])
VALUES (NEXT VALUE FOR Sequences.CustomerID, 'MyName1', 1, 4,  3200,3201, 10, 38186, 38186, 5000, convert(date,getdate()), 0, 0,0 ,7, '(978)111-1111','(978)111-1111', 'www.mysite1.com', 'shop 1', '11111', 'PO box 1', '11111', 1 )

INSERT INTO [Sales].[Customers]
           ([CustomerID],[CustomerName],[BillToCustomerID],[CustomerCategoryID],[PrimaryContactPersonID],[AlternateContactPersonID],[DeliveryMethodID],[DeliveryCityID],[PostalCityID],[CreditLimit],[AccountOpenedDate],[StandardDiscountPercentage],[IsStatementSent],[IsOnCreditHold],[PaymentDays],[PhoneNumber],[FaxNumber],[WebsiteURL],[DeliveryAddressLine1],[DeliveryPostalCode],[PostalAddressLine1],[PostalPostalCode],[LastEditedBy])
VALUES (NEXT VALUE FOR Sequences.CustomerID, 'MyName2', 1, 4,  3201,3202, 6, 38185, 38185, 1000, convert(date,getdate()), 0, 0,0 ,7, '(978)222-2222','(978)222-2222', 'www.mysite2.com', 'shop 2', '22222', 'PO box 2', '22222', 1 )

INSERT INTO [Sales].[Customers]
           ([CustomerID],[CustomerName],[BillToCustomerID],[CustomerCategoryID],[PrimaryContactPersonID],[AlternateContactPersonID],[DeliveryMethodID],[DeliveryCityID],[PostalCityID],[CreditLimit],[AccountOpenedDate],[StandardDiscountPercentage],[IsStatementSent],[IsOnCreditHold],[PaymentDays],[PhoneNumber],[FaxNumber],[WebsiteURL],[DeliveryAddressLine1],[DeliveryPostalCode],[PostalAddressLine1],[PostalPostalCode],[LastEditedBy])
VALUES (NEXT VALUE FOR Sequences.CustomerID, 'MyName3', 1, 4,  3202,3203, 7, 38184, 38184, 2000, convert(date,getdate()), 0, 0,0 ,7, '(978)333-3333','(978)333-3333', 'www.mysite3.com', 'shop 3', '33333', 'PO box 3', '33333', 1 )

INSERT INTO [Sales].[Customers]
           ([CustomerID],[CustomerName],[BillToCustomerID],[CustomerCategoryID],[PrimaryContactPersonID],[AlternateContactPersonID],[DeliveryMethodID],[DeliveryCityID],[PostalCityID],[AccountOpenedDate],[StandardDiscountPercentage],[IsStatementSent],[IsOnCreditHold],[PaymentDays],[PhoneNumber],[FaxNumber],[WebsiteURL],[DeliveryAddressLine1],[DeliveryPostalCode],[PostalAddressLine1],[PostalPostalCode],[LastEditedBy])
VALUES (NEXT VALUE FOR Sequences.CustomerID, 'MyName4', 1, 4,  3203,3204, 5, 38183, 38183,  convert(date,getdate()), 0, 0,0 ,7, '(978)444-4444','(978)444-4444', 'www.mysite4.com', 'shop 4', '44444', 'PO box 4', '44444', 1 )

INSERT INTO [Sales].[Customers]
           ([CustomerID],[CustomerName],[BillToCustomerID],[CustomerCategoryID],[PrimaryContactPersonID],[AlternateContactPersonID],[DeliveryMethodID],[DeliveryCityID],[PostalCityID],[AccountOpenedDate],[StandardDiscountPercentage],[IsStatementSent],[IsOnCreditHold],[PaymentDays],[PhoneNumber],[FaxNumber],[WebsiteURL],[DeliveryAddressLine1],[DeliveryPostalCode],[PostalAddressLine1],[PostalPostalCode],[LastEditedBy])
VALUES (NEXT VALUE FOR Sequences.CustomerID, 'MyName5', 1, 4,  3204,3205, 4, 38182, 38182,  convert(date,getdate()), 0, 0,0 ,7, '(978)555-5555','(978)555-5555', 'www.mysite5.com', 'shop 5', '55555', 'PO box 5', '55555', 1 )

/*
2. Удалите одну запись из Customers, которая была вами добавлена
*/

DELETE FROM Sales.Customers where CustomerID=1067;
DELETE FROM Sales.Customers where CustomerID= (select max(CustomerId) from Sales.Customers)

/*
3. Изменить одну запись, из добавленных через UPDATE
*/

UPDATE Sales.Customers SET DeliveryMethodID=2  
OUTPUT inserted.DeliveryMethodID as new_method,  deleted.DeliveryMethodID as old_method
WHERE CustomerID=1062;

/*
4. Написать MERGE, который вставит вставит запись в клиенты, если ее там нет, и изменит если она уже есть
*/

/* подготовили таблицу для merge
SELECT *
INTO Sales.CustomersNew
FROM Sales.Customers
WHERE CustomerName like 'MyName%';

SELECT * FROM  Sales.Customers;
SELECT * FROM  Sales.CustomersNew;
*/

MERGE Sales.Customers as target
                USING Sales.CustomersNew as source    ON (target.CustomerID = source.CustomerID)
                 WHEN MATCHED 
                        THEN UPDATE SET CustomerName = source.CustomerName,
						                DeliveryMethodId = source.DeliveryMethodId
                 WHEN NOT MATCHED 
                        THEN INSERT  (CustomerID,CustomerName,BillToCustomerID,CustomerCategoryID,PrimaryContactPersonID,AlternateContactPersonID,DeliveryMethodID,DeliveryCityID,PostalCityID,CreditLimit,AccountOpenedDate,StandardDiscountPercentage,IsStatementSent,IsOnCreditHold,PaymentDays,PhoneNumber,FaxNumber,WebsiteURL,DeliveryAddressLine1,DeliveryPostalCode,PostalAddressLine1,PostalPostalCode,LastEditedBy)
                             VALUES  (source.CustomerID,source.CustomerName,source.BillToCustomerID,source.CustomerCategoryID,source.PrimaryContactPersonID,source.AlternateContactPersonID,source.DeliveryMethodID,source.DeliveryCityID,source.PostalCityID,source.CreditLimit,source.AccountOpenedDate,source.StandardDiscountPercentage,source.IsStatementSent,source.IsOnCreditHold,source.PaymentDays,source.PhoneNumber,source.FaxNumber,source.WebsiteURL,source.DeliveryAddressLine1,source.DeliveryPostalCode,source.PostalAddressLine1,source.PostalPostalCode,source.LastEditedBy)
                           
               
                OUTPUT deleted.*, $action, inserted.*
        ;



/*
5. Напишите запрос, который выгрузит данные через bcp out и загрузить через bulk insert
*/
--выгрузка в файл
SELECT @@SERVERNAME -- MSI\OTUS
exec master..xp_cmdshell 'bcp "[WideWorldImporters].Sales.Customers" out  "D:\1\Customers1.txt" -T -w -t"^h@%"  -S MSI\OTUS'

--загрузка из файла в новую таблицу
SELECT * INTO Sales.CustomersBulk
FROM SAles.Customers
where 1=2


BULK INSERT [WideWorldImporters].[Sales].[CustomersBulk]
				   FROM "D:\1\Customers1.txt"
				   WITH 
					 (
						BATCHSIZE = 1000, 
						DATAFILETYPE = 'widechar',
						FIELDTERMINATOR = '^h@%',
						ROWTERMINATOR ='\n',
						KEEPNULLS,
						TABLOCK        
					  );
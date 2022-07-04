use WideWorldImporters;
 
 /*
 --1.выбираю таблицу для партицирования
--Warehouse.StockItemTransactions - судя по стандартному отчету, это одна из самых больших таблиц.
И наполняемость по годам более-менее равномерное.
select  year(t.TransactionOccurredWhen), count(*) from Warehouse.StockItemTransactions t group by year(t.TransactionOccurredWhen); 
select min(t.TransactionOccurredWhen) , max(t.TransactionOccurredWhen) from Warehouse.StockItemTransactions t

*/

--2. создаю новую таблицу для тест-кейса
SELECT * INTO Warehouse.StockItemTransactions_part
FROM Warehouse.StockItemTransactions ;
select * from  Warehouse.StockItemTransactions_part
--3.создаём  файловую группу
ALTER DATABASE [WideWorldImporters] ADD FILEGROUP [YearData]
GO

--4.добавляем файл БД
ALTER DATABASE [WideWorldImporters] ADD FILE 
( NAME = N'Years', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL14.OTUS\MSSQL\DATA\Yeardata.ndf' , 
SIZE = 1097152KB , FILEGROWTH = 65536KB ) TO FILEGROUP [YearData]
GO

--создаем функцию партиционирования по годам - по умолчанию left!!
CREATE PARTITION FUNCTION [fnYearPartition2](DATE) AS RANGE LEFT FOR VALUES
('20130101','20140101','20150101','20160101', '20170101',
 '20180101', '20190101', '20200101', '20210101');																																																									
GO

--5.функцию и схему пришлось создать с помощью мастера, т.к. при выборе "существующей функции" - пункт был не активен, 
--только "новая функция" - почему?
-- fnYearPartition2 - функция
-- schmYearPartition2 - схема
--когда прописывала секции - нужно выбрать последнюю ФГ и колонку оставить пустой. Иначе будет ругаться))

--6. мастер создал скрипт. Создаю функцию и схему
/*
USE [WideWorldImporters]
GO
BEGIN TRANSACTION
CREATE PARTITION FUNCTION [fnYearPartition2](datetime2(7)) AS RANGE LEFT FOR VALUES (N'2013-01-01T00:00:00', N'2014-01-01T00:00:00', N'2015-01-01T00:00:00', N'2016-01-01T00:00:00')

CREATE PARTITION SCHEME [schmYearPartition2] AS PARTITION [fnYearPartition2] TO ([YearData], [YearData], [YearData], [YearData], [YearData])

CREATE CLUSTERED INDEX [ClusteredIndex_on_schmYearPartition2_637924883962240069] ON [Warehouse].[StockItemTransactions_part]
(
	[TransactionOccurredWhen]
)WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [schmYearPartition2]([TransactionOccurredWhen])

DROP INDEX [ClusteredIndex_on_schmYearPartition2_637924883962240069] ON [Warehouse].[StockItemTransactions_part]


COMMIT TRANSACTION
*/
-- 7. левая партицированная таблица создана. 
select distinct t.name
from sys.partitions p
inner join sys.tables t
	on p.object_id = t.object_id
where p.partition_number <> 1

--8. truncate table Warehouse.StockItemTransactions_part ,чтобы проверить кейс загрузки данных:
--выгружаю данные в файл  

SELECT @@SERVERNAME -- MSI\OTUS
exec master..xp_cmdshell 'bcp "[WideWorldImporters].Warehouse.StockItemTransactions" out  "D:\1\StockItemTransactions.txt" -T -w -t "^h@%"  -S MSI\OTUS'

--загрузка из файла в новую таблицу

BULK INSERT [WideWorldImporters].[Warehouse].[StockItemTransactions_part]
				   FROM "D:\1\StockItemTransactions.txt"
				   WITH 
					 (
						BATCHSIZE = 1000, 
						DATAFILETYPE = 'widechar',
						FIELDTERMINATOR = '^h@%',
						ROWTERMINATOR ='\n',
						KEEPNULLS,
						TABLOCK        
					  );



--9.проверяю распределение

SELECT  $PARTITION.fnYearPartition2(TransactionOccurredWhen) AS Partition
		, COUNT(*) AS [COUNT]
		, MIN(TransactionOccurredWhen)
		,MAX(TransactionOccurredWhen) 
FROM Warehouse.StockItemTransactions_part
GROUP BY $PARTITION.fnYearPartition2(TransactionOccurredWhen) 
ORDER BY Partition ; 
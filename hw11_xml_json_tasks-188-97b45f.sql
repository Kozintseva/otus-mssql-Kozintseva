/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "08 - Выборки из XML и JSON полей".

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
Примечания к заданиям 1, 2:
* Если с выгрузкой в файл будут проблемы, то можно сделать просто SELECT c результатом в виде XML. 
* Если у вас в проекте предусмотрен экспорт/импорт в XML, то можете взять свой XML и свои таблицы.
* Если с этим XML вам будет скучно, то можете взять любые открытые данные и импортировать их в таблицы (например, с https://data.gov.ru).
* Пример экспорта/импорта в файл https://docs.microsoft.com/en-us/sql/relational-databases/import-export/examples-of-bulk-import-and-export-of-xml-documents-sql-server
*/


/*
1. В личном кабинете есть файл StockItems.xml.
Это данные из таблицы Warehouse.StockItems.
Преобразовать эти данные в плоскую таблицу с полями, аналогичными Warehouse.StockItems.
Поля: StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice 

Загрузить эти данные в таблицу Warehouse.StockItems: 
существующие записи в таблице обновить, отсутствующие добавить (сопоставлять записи по полю StockItemName). 

Сделать два варианта: с помощью OPENXML и через XQuery.
*/

--1 вариант с OPENXML :


-- Переменная, в которую считаем XML-файл
DECLARE @xmlDocument  xml

-- Считываем XML-файл в переменную
SELECT @xmlDocument = BulkColumn
FROM OPENROWSET
(BULK 'D:\мама\OTUS\11_xml_json\StockItems-188-1fb5df.xml', 
 SINGLE_CLOB)
as data 

-- Проверяем, что в @xmlDocument
SELECT @xmlDocument as [@xmlDocument]

DECLARE @docHandle int
EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument

SELECT @docHandle as docHandle

SELECT *
FROM OPENXML(@docHandle, N'/StockItems/Item')
WITH ( 
    [StockItemName] nvarchar(100) '@Name',
	[SupplierID] int 'SupplierID',
	[UnitPackageID] int 'Package/UnitPackageID',
	[OuterPackageID] int 'Package/OuterPackageID', 
	[QuantityPerOuter] int 'Package/QuantityPerOuter',
	[TypicalWeightPerUnit] decimal(18,3) 'Package/TypicalWeightPerUnit',
	[LeadTimeDays] int 'LeadTimeDays',
	[IsChillerStock] bit 'IsChillerStock',
	[TaxRate] decimal(18,3) 'TaxRate',
	[UnitPrice] decimal(18,2) 'UnitPrice'
	
)

DROP TABLE IF EXISTS #StockItems_xml
--создаем врем.таблицу
CREATE TABLE #StockItems_xml(
	 [StockItemName] nvarchar(100),
	[SupplierID] int,
	[UnitPackageID] int ,
	[OuterPackageID] int , 
	[QuantityPerOuter] int ,
	[TypicalWeightPerUnit] decimal(18,3),
	[LeadTimeDays] int,
	[IsChillerStock] bit ,
	[TaxRate] decimal(18,3) ,
	[UnitPrice] decimal(18,2)

)
INSERT INTO #StockItems_xml
SELECT *
FROM OPENXML(@docHandle, N'/StockItems/Item')
WITH ( 
    [StockItemName] nvarchar(100) '@Name',
	[SupplierID] int 'SupplierID',
	[UnitPackageID] int 'Package/UnitPackageID',
	[OuterPackageID] int 'Package/OuterPackageID', 
	[QuantityPerOuter] int 'Package/QuantityPerOuter',
	[TypicalWeightPerUnit] decimal(18,3) 'Package/TypicalWeightPerUnit',
	[LeadTimeDays] int 'LeadTimeDays',
	[IsChillerStock] bit 'IsChillerStock',
	[TaxRate] decimal(18,3) 'TaxRate',
	[UnitPrice] decimal(18,2) 'UnitPrice'
	)
-- Надо удалить handle
EXEC sp_xml_removedocument @docHandle

SELECT * FROM #StockItems_xml

MERGE Warehouse.StockItems as target
                USING #StockItems_xml as source  ON (target.StockItemName collate Cyrillic_General_CI_AS = source.StockItemName collate Cyrillic_General_CI_AS)
                 WHEN MATCHED 
                        THEN UPDATE SET SupplierID=source.SupplierID,
										UnitPackageID=source.UnitPackageID ,
										OuterPackageID=source.OuterPackageID , 
										QuantityPerOuter=source.QuantityPerOuter ,
										TypicalWeightPerUnit=source.TypicalWeightPerUnit,
										LeadTimeDays=source.LeadTimeDays,
										IsChillerStock=source.IsChillerStock,
										TaxRate=source.TaxRate ,
										UnitPrice=source.UnitPrice
                 WHEN NOT MATCHED 
                        THEN INSERT  (/*StockItemId, */ StockItemName, SupplierID, UnitPackageID , OuterPackageID , QuantityPerOuter ,TypicalWeightPerUnit, LeadTimeDays, IsChillerStock,TaxRate, UnitPrice,LastEditedby)
                             VALUES  (/*NEXT VALUE FOR Sequences.StockItemId, */source.StockItemName, source.SupplierID, source.UnitPackageID , source.OuterPackageID , source.QuantityPerOuter ,source.TypicalWeightPerUnit, source.LeadTimeDays, source.IsChillerStock, source.TaxRate, source.UnitPrice , 1)
                           
               
                OUTPUT deleted.*, $action, inserted.*
        ;

--2 вариант с xquery:

--объявляем переменную xml
DECLARE @xmlDocument XML
SET @xmlDocument = (SELECT * FROM OPENROWSET  (BULK 'D:\мама\OTUS\11_xml_json\StockItems-188-1fb5df.xml', SINGLE_BLOB)  as d)

DROP TABLE IF EXISTS #StockItems_xml

--врем.таблица
CREATE TABLE #StockItems_xml(
	[StockItemName] nvarchar(100),
	[SupplierID] int,
	[UnitPackageID] int ,
	[OuterPackageID] int , 
	[QuantityPerOuter] int ,
	[TypicalWeightPerUnit] decimal(18,3),
	[LeadTimeDays] int,
	[IsChillerStock] bit ,
	[TaxRate] decimal(18,3) ,
	[UnitPrice] decimal(18,2)

)
--парсим xml  во врем.таблицу
INSERT INTO #StockItems_xml
SELECT  
  t.StockItems.value('(@Name)[1]', 'nvarchar(100)') as [StockItemName],   
  t.StockItems.value('(SupplierID)[1]', 'int') as [SupplierID], 
  t.StockItems.value('(Package/UnitPackageID)[1]', 'int') as [UnitPackageID],
  t.StockItems.value('(Package/OuterPackageID)[1]', 'int') as [OuterPackageID],
  t.StockItems.value('(Package/QuantityPerOuter)[1]', 'int') as [QuantityPerOuter],
  t.StockItems.value('(Package/TypicalWeightPerUnit)[1]', 'decimal(18,3)') as [TypicalWeightPerUnit],
  t.StockItems.value('(LeadTimeDays)[1]', 'int') as [LeadTimeDays],
  t.StockItems.value('(IsChillerStock)[1]', 'bit') as [IsChillerStock],
  t.StockItems.value('(TaxRate)[1]', 'decimal(18,3)') as [TaxRate],
  t.StockItems.value('(UnitPrice)[1]', 'decimal(18,2)') as [UnitPrice]
FROM @xmlDocument.nodes('/StockItems/Item') as t(StockItems)  

SELECT * FROM #StockItems_xml;

MERGE Warehouse.StockItems as target
                USING #StockItems_xml as source  ON (target.StockItemName collate Cyrillic_General_CI_AS = source.StockItemName collate Cyrillic_General_CI_AS)
                 WHEN MATCHED 
                        THEN UPDATE SET SupplierID=source.SupplierID,
										UnitPackageID=source.UnitPackageID ,
										OuterPackageID=source.OuterPackageID , 
										QuantityPerOuter=source.QuantityPerOuter ,
										TypicalWeightPerUnit=source.TypicalWeightPerUnit,
										LeadTimeDays=source.LeadTimeDays,
										IsChillerStock=source.IsChillerStock,
										TaxRate=source.TaxRate ,
										UnitPrice=source.UnitPrice
                 WHEN NOT MATCHED 
                        THEN INSERT  (/*StockItemId, */ StockItemName, SupplierID, UnitPackageID , OuterPackageID , QuantityPerOuter ,TypicalWeightPerUnit, LeadTimeDays, IsChillerStock,TaxRate, UnitPrice,LastEditedby)
                             VALUES  (/*NEXT VALUE FOR Sequences.StockItemId, */source.StockItemName, source.SupplierID, source.UnitPackageID , source.OuterPackageID , source.QuantityPerOuter ,source.TypicalWeightPerUnit, source.LeadTimeDays, source.IsChillerStock, source.TaxRate, source.UnitPrice , 1)
                           
               
                OUTPUT deleted.*, $action, inserted.*
        ;


/*
2. Выгрузить данные из таблицы StockItems в такой же xml-файл, как StockItems.xml
*/

SELECT TOP 10
    [StockItemName] as [@Name],
	[SupplierID] as [SupplierID],
	[UnitPackageID] as  [Package/UnitPackageID],
	[OuterPackageID] as  [Package/OuterPackageID] , 
	[QuantityPerOuter] as  [Package/QuantityPerOuter],
	[TypicalWeightPerUnit] as  [Package/TypicalWeightPerUnit],
	[LeadTimeDays] as [LeadTimeDays],
	[IsChillerStock] as [IsChillerStock] ,
	[TaxRate] as [TaxRate],
	[UnitPrice] as [UnitPrice]
FROM Warehouse.StockItems
FOR XML PATH('Item'), ROOT('StockItems')
GO


/*
3. В таблице Warehouse.StockItems в колонке CustomFields есть данные в JSON.
Написать SELECT для вывода:
- StockItemID
- StockItemName
- CountryOfManufacture (из CustomFields)
- FirstTag (из поля CustomFields, первое значение из массива Tags)
*/

select CustomFields, StockItemID,  StockItemName, 
JSON_VALUE(CustomFields, '$.CountryOfManufacture') as CountryOfManufacture,
JSON_VALUE(CustomFields, '$.Tags[0]') as FirstTag
from Warehouse.StockItems

/*
4. Найти в StockItems строки, где есть тэг "Vintage".
Вывести: 
- StockItemID
- StockItemName
- (опционально) все теги (из CustomFields) через запятую в одном поле

Тэги искать в поле CustomFields, а не в Tags.
Запрос написать через функции работы с JSON.
Для поиска использовать равенство, использовать LIKE запрещено.

Должно быть в таком виде:
... where ... = 'Vintage'

Так принято не будет:
... where ... Tags like '%Vintage%'
... where ... CustomFields like '%Vintage%' 
*/

select CustomFields, Tags, StockItemID,  StockItemName,
JSON_QUERY(CustomFields, '$.Tags') as AllTags, --массив тэгов
tags.value
from Warehouse.StockItems
CROSS APPLY OPENJSON(CustomFields, '$.Tags') tags
WHERE tags.value = 'Vintage'

USE Marketing
GO

--создаю каталог
CREATE FULLTEXT CATALOG Marketing_FT_Catalog
WITH ACCENT_SENSITIVITY = ON
AS DEFAULT
AUTHORIZATION [dbo]
GO

-- создаю индекс
DROP FULLTEXT INDEX ON dbo.BulkEmail
GO
CREATE FULLTEXT INDEX ON dbo.BulkEmail(BodyLetter LANGUAGE Russian)
KEY INDEX [PK__BulkEmai__0CFCA06C3C3356CA] -- первичный ключ
ON (Marketing_FT_Catalog)
WITH (
  CHANGE_TRACKING = AUTO, 
  STOPLIST = SYSTEM  
);
GO
-- 3апускаем первоначальное заполнение
ALTER FULLTEXT INDEX ON dbo.BulkEmail
START FULL POPULATION  	


--процедура поиска по колонке BulkEmail.BodyLetter

CREATE OR ALTER PROCEDURE dbo.FindEmail
@searchtext varchar(50)
AS
SELECT be.BulkEmailID as "ID рассылки", be.Name as "Наименование рассылки", be.StartSend as "Дата рассылки", be.BodyLetter as "Текст письма"
	
FROM dbo.BulkEmail be
INNER JOIN FREETEXTTABLE(dbo.BulkEmail, BodyLetter,  @searchtext ) AS t
ON be.BulkEmailID=t.[KEY]
ORDER BY t.RANK DESC;
GO

--вызов процедуры
exec dbo.FindEmail @searchtext='обновление системы'
USE Marketing
GO

--������ �������
CREATE FULLTEXT CATALOG Marketing_FT_Catalog
WITH ACCENT_SENSITIVITY = ON
AS DEFAULT
AUTHORIZATION [dbo]
GO

-- ������ ������
DROP FULLTEXT INDEX ON dbo.BulkEmail
GO
CREATE FULLTEXT INDEX ON dbo.BulkEmail(BodyLetter LANGUAGE Russian)
KEY INDEX [PK__BulkEmai__0CFCA06C3C3356CA] -- ��������� ����
ON (Marketing_FT_Catalog)
WITH (
  CHANGE_TRACKING = AUTO, 
  STOPLIST = SYSTEM  
);
GO
-- 3�������� �������������� ����������
ALTER FULLTEXT INDEX ON dbo.BulkEmail
START FULL POPULATION  	


--��������� ������ �� ������� BulkEmail.BodyLetter

CREATE OR ALTER PROCEDURE dbo.FindEmail
@searchtext varchar(50)
AS
SELECT be.BulkEmailID as "ID ��������", be.Name as "������������ ��������", be.StartSend as "���� ��������", be.BodyLetter as "����� ������"
	
FROM dbo.BulkEmail be
INNER JOIN FREETEXTTABLE(dbo.BulkEmail, BodyLetter,  @searchtext ) AS t
ON be.BulkEmailID=t.[KEY]
ORDER BY t.RANK DESC;
GO

--����� ���������
exec dbo.FindEmail @searchtext='���������� �������'
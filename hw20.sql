/*
1) ������� ����� SQLsharp_SETUP.zip
2) ���������� ������ SQL SQLsharp_SETUP:
--������� ������ ����� ���������
 *** SQL# (SQLsharp) 4.2.100 has been installed!!
 
 
Setup Procedure Completed.
 
 
SQL# Installed!!
 
 
!!! Please scroll up to see the warning about the Collation mismatch !!!
 

Completion time: 2022-06-27T18:28:14.7691021+03:00
*/
-- 3) ��������� �������, ����� DaysInMonth
CREATE FUNCTION fn_DaysInMonth(@Year [int], @Month [int])
RETURNS [int] WITH EXECUTE AS CALLER, RETURNS NULL ON NULL INPUT
AS 
EXTERNAL NAME [SQL#].[DATE].[DaysInMonth]
GO

--�����
select dbo.fn_DaysInMonth (2021, 11) ;
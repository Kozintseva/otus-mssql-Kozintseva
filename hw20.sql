/*
1) скачала архив SQLsharp_SETUP.zip
2) установила скрипт SQL SQLsharp_SETUP:
--кусочек принта после установки
 *** SQL# (SQLsharp) 4.2.100 has been installed!!
 
 
Setup Procedure Completed.
 
 
SQL# Installed!!
 
 
!!! Please scroll up to see the warning about the Collation mismatch !!!
 

Completion time: 2022-06-27T18:28:14.7691021+03:00
*/
-- 3) подключаю функцию, метод DaysInMonth
CREATE FUNCTION fn_DaysInMonth(@Year [int], @Month [int])
RETURNS [int] WITH EXECUTE AS CALLER, RETURNS NULL ON NULL INPUT
AS 
EXTERNAL NAME [SQL#].[DATE].[DaysInMonth]
GO

--вызов
select dbo.fn_DaysInMonth (2021, 11) ;
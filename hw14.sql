-- 1. �������� ��������� ��:

CREATE DATABASE [Marketing]
 CONTAINMENT = NONE
 ON  PRIMARY     ---�������� ������ PRIMARY
( NAME = marketing, FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL14.OTUS\MSSQL\DATA\marketing.mdf' ,   ---���� ������
	SIZE = 8MB ,    --- min ������
	MAXSIZE = UNLIMITED,   ---max ������
	FILEGROWTH = 65536KB )    ---���������� (��� � ���� ����, ��� ����� %)
 LOG ON 
( NAME = marketing_log, FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL14.OTUS\MSSQL\DATA\marketing.ldf' , ---���� �����
	SIZE = 8MB , 
	MAXSIZE = 10GB , 
	FILEGROWTH = 65536KB )
GO

-- 2. �������� �������� ������
--2.1. ������� � ���������
USE Marketing
GO

CREATE TABLE [Clients] (
	ClientId int NOT NULL PRIMARY KEY DEFAULT (NEXT VALUE FOR Sequences.OwnerID_seq),
	FirstName nvarchar(50),
	LastName nvarchar(50),
	SecondName nvarchar(50),
	INN nvarchar(14),
	sex int NOT NULL,
	BirthDt date NOT NULL,
	Age int NOT NULL,
	Country nvarchar(250),
	Region nvarchar(250),
	City nvarchar(250),
	Street nvarchar,
	House int,
	Flat int
)
GO

--2.2. ������� ���-��������

CREATE TABLE [BulkSMS] (
	BulkSmsId int NOT NULL PRIMARY KEY,
	Name nvarchar(250) NOT NULL,
	StartSend datetime NOT NULL,
	EndSend datetime NOT NULL,
	StatusId int NOT NULL,
	MessageText nvarchar(max) NOT NULL,
	ProductId int
    
)
GO
--2.3 ������� � ����������� ������� ��������
CREATE TABLE [Contacts] (
	ContactId int NOT NULL PRIMARY KEY,
	ClientId int NOT NULL,
	Contact nvarchar(250),
	TypeContact int NOT NULL
 
)
GO
--2.4 ���������� �������� �������
CREATE TABLE [StatusAll] (
	StatusId int NOT NULL PRIMARY KEY,
	StatusName nvarchar(50) NOT NULL,
	Describe nvarchar(max)
 
)
GO

-- 2.5 ������� � ����������� ���-��������
CREATE TABLE [SmsTarget] (
	SmsTargetId int NOT NULL PRIMARY KEY,
	ClientId int NOT NULL,
	BulkSmsId int NOT NULL,
	StatusId int NOT NULL,
	DestPhone varchar(50)
)
GO

--2.6 sequence
CREATE SCHEMA [Sequences];
CREATE SEQUENCE [Sequences].[OwnerID_seq] 
 AS [int]
 START WITH 1000
 INCREMENT BY 1
 MINVALUE -2147483648
 MAXVALUE 2147483647
 CACHE 
GO

--3. ������� �����:
ALTER TABLE [Contacts] WITH CHECK ADD CONSTRAINT [FK_Contacts_Client] FOREIGN KEY ([ClientId]) REFERENCES [Clients]([ClientId])
ON UPDATE CASCADE
GO
ALTER TABLE [Contacts] CHECK CONSTRAINT [FK_Contacts_Client]
GO

ALTER TABLE [BulkSMS] WITH CHECK ADD CONSTRAINT [FK_BulkSMS_StatusAll] FOREIGN KEY ([StatusId]) REFERENCES [StatusAll]([StatusId])
ON UPDATE CASCADE
GO
ALTER TABLE [BulkSMS] CHECK CONSTRAINT [FK_BulkSMS_StatusAll]
GO


ALTER TABLE [SmsTarget] WITH CHECK ADD CONSTRAINT [FK_SmsTarget_Clients] FOREIGN KEY ([ClientId]) REFERENCES [Clients]([ClientId])
ON UPDATE CASCADE
GO
ALTER TABLE [SmsTarget] CHECK CONSTRAINT [FK_SmsTarget_Clients]
GO
ALTER TABLE [SmsTarget] WITH CHECK ADD CONSTRAINT [FK_SmsTarget_BulkSMS] FOREIGN KEY ([BulkSmsId]) REFERENCES [BulkSMS]([BulkSmsId])
ON UPDATE CASCADE
GO
ALTER TABLE [SmsTarget] CHECK CONSTRAINT [FK_SmsTarget_BulkSMS]
GO
ALTER TABLE [SmsTarget] WITH CHECK ADD CONSTRAINT [FK_SmsTarget_StatusAll] FOREIGN KEY ([StatusId]) REFERENCES [StatusAll]([StatusId])
ON UPDATE CASCADE
GO
ALTER TABLE [SmsTarget] CHECK CONSTRAINT [FK_SmsTarget_StatusAll]
GO
ALTER TABLE [SmsTarget] WITH CHECK ADD CONSTRAINT [FK_SmsTarget_Contacts] FOREIGN KEY ([DestPhone]) REFERENCES [Contacts]([Contact])
ON UPDATE CASCADE
GO
ALTER TABLE [SmsTarget] CHECK CONSTRAINT [FK_SmsTarget_Contacts]
GO

--4.����������� �� �������� ��� �� ����� �������� � ����� 7 ����
ALTER TABLE SmsTarget ADD CONSTRAINT constr_phone
		CHECK (LEN(DestPhone)<7);
		
		
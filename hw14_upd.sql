-- 1. Создание проектной БД:

CREATE DATABASE [Marketing]
 CONTAINMENT = NONE
 ON  PRIMARY     ---файловая группа PRIMARY
( NAME = marketing, FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL14.OTUS\MSSQL\DATA\marketing.mdf' ,   ---файл данных
	SIZE = 8MB ,    --- min размер
	MAXSIZE = UNLIMITED,   ---max размер
	FILEGROWTH = 65536KB )    ---приращение (или в виде шага, или через %)
 LOG ON 
( NAME = marketing_log, FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL14.OTUS\MSSQL\DATA\marketing.ldf' , ---файл логов
	SIZE = 8MB , 
	MAXSIZE = 10GB , 
	FILEGROWTH = 65536KB )
GO

-- 2. создание основных таблиц
--2.1. Таблица с клиентами
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

--2.2. Таблица СМС-рассылок

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
--2.3 Таблица с контактными данными клиентов
CREATE TABLE [Contacts] (
	ContactId int NOT NULL PRIMARY KEY,
	ClientId int NOT NULL,
	Contact nvarchar(250),
	TypeContact int NOT NULL
 
)
GO
--2.4 Справочник статусов событий

CREATE TABLE [StatusAll] (
	StatusId int NOT NULL PRIMARY KEY,
	StatusName nvarchar(50) NOT NULL,
	Describe nvarchar(max)
 
)
GO
--справочник продуктов
CREATE TABLE [Products] (
	ProductId int NOT NULL PRIMARY KEY DEFAULT (NEXT VALUE FOR Sequences.OwnerID_seq),
	ProductName nvarchar(50) NOT NULL,
	EndDate date NOT NULL,
	)
GO

-- 2.5 Таблица с аудиториями СМС-рассылок
CREATE TABLE [SmsTarget] (
	SmsTargetId int NOT NULL PRIMARY KEY,
	ClientId int NOT NULL,
	BulkSmsId int NOT NULL,
	StatusId int NOT NULL,
	DestPhone varchar(50)
)
GO

--2.6 таблица с email-рассылками

CREATE TABLE [BulkEmail] (
	BulkEmailId int NOT NULL PRIMARY KEY DEFAULT (NEXT VALUE FOR Sequences.OwnerID_seq),
	Name nvarchar(250) NOT NULL,
	ProductId int,
	StartSend datetime NOT NULL,
	EndSend datetime NOT NULL,
	StatusId int NOT NULL,
	Caption nvarchar(250) NOT NULL,
	BodyLetter nvarchar(max)

)
GO

--таблица аудиторий email-рассылок
CREATE TABLE [EmailTarget] (
	EmailTargetId int NOT NULL PRIMARY KEY DEFAULT (NEXT VALUE FOR Sequences.OwnerID_seq),
	ClientId int NOT NULL,
	BulkEmailId int NOT NULL,
	StatusId int NOT NULL,
    Email varchar(50)

)
GO

--cправочник отделений
CREATE TABLE [Departments] (
	DepId int NOT NULL ,
	DepName nvarchar(250) NOT NULL,
	DepAddress nvarchar(max),
  CONSTRAINT [PK_DEPARTMENTS] PRIMARY KEY CLUSTERED
  (
  [DepId] ASC
  ) WITH (IGNORE_DUP_KEY = OFF)

)
GO
--пользователи 

CREATE TABLE [Users] (
	UserId int NOT NULL PRIMARY KEY DEFAULT (NEXT VALUE FOR Sequences.UserID_seq),
	UserName nvarchar(250) NOT NULL,
	TabN nvarchar(10) NOT NULL,
	DepId int NOT NULL

)
GO
--таблица событий
CREATE TABLE [BulkEvent] (
	EventId int NOT NULL,
	CreatedOn datetime NOT NULL,
	CreatedUser int NOT NULL,
	ChangedOn datetime NOT NULL,
	ChangedUser int NOT NULL,
	Module nvarchar(10) NOT NULL,
  CONSTRAINT [PK_BULKEVENT] PRIMARY KEY CLUSTERED
  (
  [EventId] ASC
  ) WITH (IGNORE_DUP_KEY = OFF)

)
GO


CREATE TABLE [BulkEventHistory] (
	EventHId int NOT NULL,
	EventId int NOT NULL,
	ChangedOn datetime NOT NULL,
	UserId int NOT NULL,
	OperCode nvarchar(50) NOT NULL,
	StatusOld nvarchar(50),
	StatusNew nvarchar(50),
	Comment nvarchar(250),
  CONSTRAINT [PK_BULKEVENTHISTORY] PRIMARY KEY CLUSTERED
  (
  [EventHId] ASC
  ) WITH (IGNORE_DUP_KEY = OFF)

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

CREATE SEQUENCE [Sequences].[UserID_seq] 
 AS [int]
 START WITH 10
 INCREMENT BY 1
 MINVALUE -2147483648
 MAXVALUE 2147483647
 CACHE 
GO
--3. внешние ключи:
ALTER TABLE [Contacts] WITH CHECK ADD CONSTRAINT [FK_Contacts_Client] FOREIGN KEY ([ClientId]) REFERENCES [Clients]([ClientId])
ON UPDATE CASCADE
GO
ALTER TABLE [Contacts] CHECK CONSTRAINT [FK_Contacts_Client]
GO
ALTER TABLE [BulkEvent] WITH CHECK ADD CONSTRAINT [FK_BulkEvent_Users] FOREIGN KEY ([CreatedUser]) REFERENCES [Users]([UserId])
ON UPDATE CASCADE
GO
ALTER TABLE [BulkEvent] CHECK CONSTRAINT [FK_BulkEvent_Users]
GO
ALTER TABLE [BulkEvent] WITH CHECK ADD CONSTRAINT [FK_BulkEvent_Users_ch] FOREIGN KEY ([ChangedUser]) REFERENCES [Users]([UserId])

GO
ALTER TABLE [BulkEvent] CHECK CONSTRAINT [FK_BulkEvent_Users_ch]
GO
ALTER TABLE [BulkEventHistory] WITH CHECK ADD CONSTRAINT [FK_BulkEventHistory_Users] FOREIGN KEY ([UserId]) REFERENCES [Users]([UserId])
ON UPDATE CASCADE
GO
ALTER TABLE [BulkEventHistory] CHECK CONSTRAINT [FK_BulkEventHistory_Users]
GO

ALTER TABLE [Users] WITH CHECK ADD CONSTRAINT [FK_Users_Departments] FOREIGN KEY ([DepId]) REFERENCES [Departments]([DepId])
ON UPDATE CASCADE
GO
ALTER TABLE [Users] CHECK CONSTRAINT [FK_Users_Departments]
GO

ALTER TABLE [BulkSMS] WITH CHECK ADD CONSTRAINT [FK_BulkSMS_StatusAll] FOREIGN KEY ([StatusId]) REFERENCES [StatusAll]([StatusId])
ON UPDATE CASCADE
GO
ALTER TABLE [BulkSMS] CHECK CONSTRAINT [FK_BulkSMS_StatusAll]
GO
ALTER TABLE [BulkSMS] WITH CHECK ADD CONSTRAINT [FK_BulkSMS_Products] FOREIGN KEY ([ProductId]) REFERENCES [Products]([ProductId])
ON UPDATE CASCADE
GO
ALTER TABLE [BulkSMS] CHECK CONSTRAINT [FK_BulkSMS_Products]
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

GO
ALTER TABLE [SmsTarget] CHECK CONSTRAINT [FK_SmsTarget_StatusAll]
GO

ALTER TABLE [BulkEmail] WITH CHECK ADD CONSTRAINT [FK_BulkEmail_StatusAll] FOREIGN KEY ([StatusId]) REFERENCES [StatusAll]([StatusId])
ON UPDATE CASCADE
GO
ALTER TABLE [BulkEmail] CHECK CONSTRAINT [FK_BulkEmail_StatusAll]
GO
ALTER TABLE [BulkEmail] WITH CHECK ADD CONSTRAINT [FK_BulkEmail_Products] FOREIGN KEY ([ProductId]) REFERENCES [Products]([ProductId])
ON UPDATE CASCADE
GO
ALTER TABLE [BulkEmail] CHECK CONSTRAINT [FK_BulkEmail_Products]
GO

ALTER TABLE [EmailTarget] WITH CHECK ADD CONSTRAINT [FK_EmailTarget_Clients] FOREIGN KEY ([ClientId]) REFERENCES [Clients]([ClientId])
ON UPDATE CASCADE
GO
ALTER TABLE [EmailTarget] CHECK CONSTRAINT [FK_EmailTarget_Clients]
GO
ALTER TABLE [EmailTarget] WITH CHECK ADD CONSTRAINT [FK_EmailTarget_BulkEmail] FOREIGN KEY ([BulkEmailId]) REFERENCES [BulkEmail]([BulkEmailId])
ON UPDATE CASCADE
GO
ALTER TABLE [EmailTarget] CHECK CONSTRAINT [FK_EmailTarget_BulkEmail]
GO
ALTER TABLE [EmailTarget] WITH CHECK ADD CONSTRAINT [FK_EmailTarget_StatusAll] FOREIGN KEY ([StatusId]) REFERENCES [StatusAll]([StatusId])
GO
ALTER TABLE [EmailTarget] CHECK CONSTRAINT [FK_EmailTarget_StatusAll]
GO



--4.ограничение на отправку смс на номер телефона с менее 7 цифр
ALTER TABLE SmsTarget ADD CONSTRAINT constr_phone
		CHECK (LEN(DestPhone)<7);
 --значение по-умолчанию
ALTER TABLE Products ADD CONSTRAINT default_date
		DEFAULT '01.01.5555' FOR EndDate;		

--5.Индексы.
--5.1. колоночный индекс

CREATE COLUMNSTORE INDEX IX_SmsTarget_ClientId
ON dbo.SmsTarget(ClientId)
GO

--5.2. 
CREATE INDEX IX_SmsTarget_DestPhone
ON dbo.SmsTarget(DestPhone)
GO

CREATE INDEX IX_BulkSms_Name
ON dbo.BulkSms(Name)
GO

CREATE INDEX IX_BulkSMS_StartSend
ON dbo.BulkSMS(StartSend)
GO

CREATE INDEX IX_BulkEmail_Name
ON dbo.BulkEmail(Name)
GO
CREATE INDEX IX_BulkEmail_StartSend
ON dbo.BulkEmail(StartSend)
GO

--5.3 составной индекс
CREATE INDEX IX_BulkEvent_CreatedUser_CreatedOn
ON dbo.BulkEvent(CreatedUser, CreatedOn)
GO
-- 5.3. полнотекстовый
--1. Создаем полнотекстовый каталог
USE Marketing
GO

CREATE FULLTEXT CATALOG Marketing_FT_Catalog
WITH ACCENT_SENSITIVITY = ON
AS DEFAULT
AUTHORIZATION [dbo]
GO

--5.2 создаем индекс
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
-- 5.3апускаем первоначальное заполнение
ALTER FULLTEXT INDEX ON dbo.BulkEmail
START FULL POPULATION  	
--запрос
SELECT *
FROM dbo.BulkEmail be 
WHERE CONTAINS(be.BodyLetter, N'продлить');
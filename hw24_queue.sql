--1.проверить что брокер включен  - включен 
select name, is_broker_enabled
from sys.databases;

 --2.авторизация для sa
ALTER AUTHORIZATION    
   ON DATABASE::Marketing TO [sa];  


---3. создаем типы сообщение и сервисный контракт
--от отправителя
CREATE MESSAGE TYPE
[//Marketing/SB/RequestMessage]  
VALIDATION=WELL_FORMED_XML; 
-- от получателя
CREATE MESSAGE TYPE
[//Marketing/SB/ReplyMessage]
VALIDATION=WELL_FORMED_XML; GO
--создаем контракт
CREATE CONTRACT [//Marketing/SB/Contract]
      ([//Marketing/SB/RequestMessage]
         SENT BY INITIATOR,
       [//Marketing/SB/ReplyMessage]
         SENT BY TARGET
      );
GO

--4. создаем очереди и сервис
--инициатор-очередь и инициатор - сервис
CREATE QUEUE MarketingInitiatorQueue;  

CREATE SERVICE [//Marketing/SB/InitiatorService]
       ON QUEUE MarketingInitiatorQueue
       ([//Marketing/SB/Contract]);
GO
--создаем очередь-получатель и получатель-сервис
CREATE QUEUE MarketingTargetQueue;   

CREATE SERVICE [//Marketing/SB/TargetService]
       ON QUEUE MarketingTargetQueue
       ([//Marketing/SB/Contract]);
GO



--5. положить сообщение в очередь через процедуру SendNewReport
--сообщение состоит из пользователя по которому формирвоать отчет, периода и Id отчета:
SELECT 
    [Name] as [@Name],
	[BulkReportsId] as [BulkReportId],
	[CreatedByUser] as [CreatedByUser],
	[DateStart] as  [DateStart],
	[DateFinish] as  [DateFinish]  
	
FROM BulkReport
FOR XML PATH('Report'), ROOT('BulkReport')
GO

--Процедура отправки в очередь:
CREATE OR ALTER PROCEDURE SendNewReport
	@ReportId INT   --в переменную будем передавать BulkReportsId  
AS
BEGIN
	SET NOCOUNT ON;

    
	DECLARE @InitDlgHandle UNIQUEIDENTIFIER;  --идентификатор диалога
	DECLARE @RequestMessage NVARCHAR(4000);   --и само сообщение, которое создаем
	
	BEGIN TRAN  -- работа с очередями через транзакции

	--формируем сообщение 
	
SELECT @RequestMessage = ( SELECT 
							[Name] as [@Name],
							[BulkReportsId] as [BulkReportId],
							[CreatedByUser] as [CreatedByUser],
							[DateStart] as  [DateStart],
							[DateFinish] as  [DateFinish]  
							FROM BulkReport
							where BulkReportsId = @ReportId
							FOR XML PATH('Report'), ROOT('BulkReport'));

	--открываем диалог между сервисами: от сервиса-иницатора [//Marketing/SB/InitiatorService] к сервису-получателю [//Marketing/SB/TargetService] по контракту [//Marketing/SB/Contract] , 
	--и отправляем сообщение в очередь Target !!!

	BEGIN DIALOG @InitDlgHandle
	FROM SERVICE
	[//Marketing/SB/InitiatorService]
	TO SERVICE
	'//Marketing/SB/TargetService'
	ON CONTRACT
	[//Marketing/SB/Contract]
	WITH ENCRYPTION=OFF; 

	-- отправить сообщение в рамках открытого диалога, с типом [//WWI/SB/RequestMessage] и само сообщение (@RequestMessage)
	SEND ON CONVERSATION @InitDlgHandle 
	MESSAGE TYPE
	[//Marketing/SB/RequestMessage]
	(@RequestMessage);
	--SELECT @RequestMessage AS SentRequestMessage;
	COMMIT TRAN 
END
GO


--6. процедура обработки сообщения на сервере получателя - получили сообщение, вызвали процедуру формирвоания отчета и отправили ответ

CREATE OR ALTER PROCEDURE GetNewReport
AS
BEGIN

	DECLARE @TargetDlgHandle UNIQUEIDENTIFIER,
			@Message xml,
			@MessageType Sysname,
			@ReplyMessage NVARCHAR(4000),
			@ReplyMessageName Sysname,
			@NameReport nvarchar(250),
			@ReportID INT,
			 @BulkReportsId INT,
			@CreatedByUser INT,
			@DateStart DATE,
			@DateFinish DATE,
			@xml XML; 
	      
	BEGIN TRAN; --начало транзакции

	
	RECEIVE TOP(1)  --получаем 1 сообщение из очереди dbo.MarketingTargetQueue 
		@TargetDlgHandle = Conversation_Handle,   --идентификатор диалога
		@Message = Message_Body,                  -- выбираем сообщение
		@MessageType = Message_Type_Name          -- и тип сообщения
	FROM dbo.MarketingTargetQueue; 

	SELECT @Message as MSG;

--	SET @xml = CAST(@Message AS XML);
	--выбираем данные из сообщения и передаем в процедуру формирования отчета  (формирует отчет и добавляет его в таблицу отчетов BulkReport и апдейтит еиу статус)

SELECT  
  @NameReport= t.BulkReport.value('(@Name)[1]', 'nvarchar(100)'),   
 @BulkReportsId= t.BulkReport.value('(BulkReportId)[1]', 'int'), 
  @CreatedByUser=t.BulkReport.value('(CreatedByUser)[1]', 'int') ,
  @DateStart=t.BulkReport.value('(DateStart)[1]', 'date') ,
  @DateFinish=t.BulkReport.value('(DateFinish)[1]', 'date')
 
FROM @Message.nodes('/BulkReport/Report') as t(BulkReport)  

DROP TABLE IF EXISTS #test 

--врем.таблица
create table #test (Name nvarchar(100), ReportID int,CreatedByUser int, DateStart date, DateFinish date );
insert into #test (Name , ReportID ,CreatedByUser , DateStart, DateFinish )
values (@NameReport, @BulkReportsId, @CreatedByUser, @DateStart, @DateFinish )
SELECT * FROM #test;

--вызываю процедуру формирвоания отчета (передаю номер отчета, период и пользователя, процедура формирует xml и складывает в таблицу BulkReportResult и обновляет статус заказа)
   exec CreateReportUser @ReportID= @BulkReportsId, @UserId=  @CreatedByUser , @DateStart =  @DateStart, @DateFinish =@DateFinish ;
	SELECT @Message AS ReceivedRequestMessage, @MessageType; 
	
	-- отвечаем сообщением "Message received"

	IF @MessageType=N'//Marketing/SB/RequestMessage'
	BEGIN
		SET @ReplyMessage =N'<ReplyMessage>Report created</ReplyMessage>'; 
	
		SEND ON CONVERSATION @TargetDlgHandle
		MESSAGE TYPE
		[//Marketing/SB/ReplyMessage]
		(@ReplyMessage);
		END CONVERSATION @TargetDlgHandle;  -- закрываем диалог 
	END 
	
	SELECT @ReplyMessage AS SentReplyMessage; 

	COMMIT TRAN;
END


--7. процедура формирвоания отчета, вызываю в GetNewReport: формирую отчет по созданным пользователем кампаниям за период
create      PROCEDURE  [dbo].[CreateReportUser]
	@ReportID int,
	@UserId int,
	@DateStart date,
	@DateFinish date
    AS
	
	  DECLARE @Message xml; 
	
	set @Message = (SELECT 
	[Name] as [@Name],
	[CreatedOn] as [CreatedOn],
	[CreatedUser] as [CreatedUser]
	FROM  BulkSMS s
	left join BulkEvent e on s.BulkSmsId=e.EventId
	where CreatedUser = @UserID
	AND CreatedOn between @DateStart and @DateFinish 
	FOR XML PATH('Report'), ROOT('BulkReport'));
	Select @Message;
	insert into BulkReportResult   ( BulkReportsId,Result) 
	VALUES (@ReportId, @Message);
	
	update BulkReport SET [StatusId] = 6 
    WHERE [BulkReportsId] = @ReportId;

GO

--8.обработка сообщения на сервере-отправителе (обрабатывает ответы  "Message received" от получателя и закрывает диалог)

CREATE PROCEDURE ConfirmReport
AS
BEGIN
	--Receiving Reply Message from the Target.	
	DECLARE @InitiatorReplyDlgHandle UNIQUEIDENTIFIER,
			@ReplyReceivedMessage NVARCHAR(1000) 
	
	BEGIN TRAN; 
	--получает сообщение (они все одинаковые), закрывает диалог, и завершает транзакцию
		RECEIVE TOP(1)
			@InitiatorReplyDlgHandle=Conversation_Handle
			,@ReplyReceivedMessage=Message_Body
		FROM dbo.MarketingInitiatorQueue; 
		
		END CONVERSATION @InitiatorReplyDlgHandle; 
		
		SELECT @ReplyReceivedMessage AS ReceivedRepliedMessage; 

	COMMIT TRAN; 
END


--9.alter QUEUE

USE [Marketing]
GO
--если статус STATUS = OFF - в очередь ничего нельзя добавить
-- ACTIVATION (   STATUS = ON - статус активации означает, что при добавлении сообщения в очередь, будет запускаться процедура обработки PROCEDURE_NAME = Sales.ConfirmInvoice
--т.е. наша процедура обработки сообщений
--MAX_QUEUE_READERS - от 1 до 32000 - сколько воркеров будет обрабатывать очередь
--POISON_MESSAGE_HANDLING  - здесь определяем очередь, куда будут попадать сообщения, которые не получается обработать, через сколько-то попыток
ALTER QUEUE [dbo].[MarketingInitiatorQueue] WITH STATUS = ON , RETENTION = OFF , POISON_MESSAGE_HANDLING (STATUS = OFF) 
	, ACTIVATION (   STATUS = OFF,
        PROCEDURE_NAME = dbo.ConfirmReport, MAX_QUEUE_READERS = 1, EXECUTE AS OWNER) ; 

GO
ALTER QUEUE [dbo].[MarketingTargetQueue] WITH STATUS = ON , RETENTION = OFF , POISON_MESSAGE_HANDLING (STATUS = OFF)
	, ACTIVATION (  STATUS = OFF,
        PROCEDURE_NAME = dbo.GetNewReport, MAX_QUEUE_READERS = 1, EXECUTE AS OWNER) ; 

GO

--10.запускаем весь процесс

-- сформируем отчет для заказа отчета 1005
SELECT * FROM BulkReport WHERE BulkReportsID = 1005;

--отправить сообщение с BulkReportsID = 1005 в очередь MarketingTargetQueue.
--можно вызыватьЮ, например, в конце процедуры обработки платежа - платеж приняли, обработали и иотправляем его в очередь, чтобы он попал на дрюсервера
EXEC SendNewReport @ReportId = 1005;

--выборки из очереди:
SELECT CAST(message_body AS XML),*
FROM dbo.MarketingTargetQueue;

SELECT CAST(message_body AS XML),*
FROM dbo.MarketingInitiatorQueue;

--получение и обработка
EXEC GetNewReport;
SELECT * FROM BulkReport WHERE BulkReportsID = 1005;
SELECT * FROM BulkReportResult   WHERE BulkReportsID = 1005;
--Initiator
EXEC dbo.ConfirmReport;

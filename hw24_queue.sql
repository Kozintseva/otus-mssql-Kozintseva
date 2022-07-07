--1.��������� ��� ������ �������  - ������� 
select name, is_broker_enabled
from sys.databases;

 --2.����������� ��� sa
ALTER AUTHORIZATION    
   ON DATABASE::Marketing TO [sa];  


---3. ������� ���� ��������� � ��������� ��������
--�� �����������
CREATE MESSAGE TYPE
[//Marketing/SB/RequestMessage]  
VALIDATION=WELL_FORMED_XML; 
-- �� ����������
CREATE MESSAGE TYPE
[//Marketing/SB/ReplyMessage]
VALIDATION=WELL_FORMED_XML; GO
--������� ��������
CREATE CONTRACT [//Marketing/SB/Contract]
      ([//Marketing/SB/RequestMessage]
         SENT BY INITIATOR,
       [//Marketing/SB/ReplyMessage]
         SENT BY TARGET
      );
GO

--4. ������� ������� � ������
--���������-������� � ��������� - ������
CREATE QUEUE MarketingInitiatorQueue;  

CREATE SERVICE [//Marketing/SB/InitiatorService]
       ON QUEUE MarketingInitiatorQueue
       ([//Marketing/SB/Contract]);
GO
--������� �������-���������� � ����������-������
CREATE QUEUE MarketingTargetQueue;   

CREATE SERVICE [//Marketing/SB/TargetService]
       ON QUEUE MarketingTargetQueue
       ([//Marketing/SB/Contract]);
GO



--5. �������� ��������� � ������� ����� ��������� SendNewReport
--��������� ������� �� ������������ �� �������� ����������� �����, ������� � Id ������:
SELECT 
    [Name] as [@Name],
	[BulkReportsId] as [BulkReportId],
	[CreatedByUser] as [CreatedByUser],
	[DateStart] as  [DateStart],
	[DateFinish] as  [DateFinish]  
	
FROM BulkReport
FOR XML PATH('Report'), ROOT('BulkReport')
GO

--��������� �������� � �������:
CREATE OR ALTER PROCEDURE SendNewReport
	@ReportId INT   --� ���������� ����� ���������� BulkReportsId  
AS
BEGIN
	SET NOCOUNT ON;

    
	DECLARE @InitDlgHandle UNIQUEIDENTIFIER;  --������������� �������
	DECLARE @RequestMessage NVARCHAR(4000);   --� ���� ���������, ������� �������
	
	BEGIN TRAN  -- ������ � ��������� ����� ����������

	--��������� ��������� 
	
SELECT @RequestMessage = ( SELECT 
							[Name] as [@Name],
							[BulkReportsId] as [BulkReportId],
							[CreatedByUser] as [CreatedByUser],
							[DateStart] as  [DateStart],
							[DateFinish] as  [DateFinish]  
							FROM BulkReport
							where BulkReportsId = @ReportId
							FOR XML PATH('Report'), ROOT('BulkReport'));

	--��������� ������ ����� ���������: �� �������-��������� [//Marketing/SB/InitiatorService] � �������-���������� [//Marketing/SB/TargetService] �� ��������� [//Marketing/SB/Contract] , 
	--� ���������� ��������� � ������� Target !!!

	BEGIN DIALOG @InitDlgHandle
	FROM SERVICE
	[//Marketing/SB/InitiatorService]
	TO SERVICE
	'//Marketing/SB/TargetService'
	ON CONTRACT
	[//Marketing/SB/Contract]
	WITH ENCRYPTION=OFF; 

	-- ��������� ��������� � ������ ��������� �������, � ����� [//WWI/SB/RequestMessage] � ���� ��������� (@RequestMessage)
	SEND ON CONVERSATION @InitDlgHandle 
	MESSAGE TYPE
	[//Marketing/SB/RequestMessage]
	(@RequestMessage);
	--SELECT @RequestMessage AS SentRequestMessage;
	COMMIT TRAN 
END
GO


--6. ��������� ��������� ��������� �� ������� ���������� - �������� ���������, ������� ��������� ������������ ������ � ��������� �����

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
	      
	BEGIN TRAN; --������ ����������

	
	RECEIVE TOP(1)  --�������� 1 ��������� �� ������� dbo.MarketingTargetQueue 
		@TargetDlgHandle = Conversation_Handle,   --������������� �������
		@Message = Message_Body,                  -- �������� ���������
		@MessageType = Message_Type_Name          -- � ��� ���������
	FROM dbo.MarketingTargetQueue; 

	SELECT @Message as MSG;

--	SET @xml = CAST(@Message AS XML);
	--�������� ������ �� ��������� � �������� � ��������� ������������ ������  (��������� ����� � ��������� ��� � ������� ������� BulkReport � �������� ��� ������)

SELECT  
  @NameReport= t.BulkReport.value('(@Name)[1]', 'nvarchar(100)'),   
 @BulkReportsId= t.BulkReport.value('(BulkReportId)[1]', 'int'), 
  @CreatedByUser=t.BulkReport.value('(CreatedByUser)[1]', 'int') ,
  @DateStart=t.BulkReport.value('(DateStart)[1]', 'date') ,
  @DateFinish=t.BulkReport.value('(DateFinish)[1]', 'date')
 
FROM @Message.nodes('/BulkReport/Report') as t(BulkReport)  

DROP TABLE IF EXISTS #test 

--����.�������
create table #test (Name nvarchar(100), ReportID int,CreatedByUser int, DateStart date, DateFinish date );
insert into #test (Name , ReportID ,CreatedByUser , DateStart, DateFinish )
values (@NameReport, @BulkReportsId, @CreatedByUser, @DateStart, @DateFinish )
SELECT * FROM #test;

--������� ��������� ������������ ������ (������� ����� ������, ������ � ������������, ��������� ��������� xml � ���������� � ������� BulkReportResult � ��������� ������ ������)
   exec CreateReportUser @ReportID= @BulkReportsId, @UserId=  @CreatedByUser , @DateStart =  @DateStart, @DateFinish =@DateFinish ;
	SELECT @Message AS ReceivedRequestMessage, @MessageType; 
	
	-- �������� ���������� "Message received"

	IF @MessageType=N'//Marketing/SB/RequestMessage'
	BEGIN
		SET @ReplyMessage =N'<ReplyMessage>Report created</ReplyMessage>'; 
	
		SEND ON CONVERSATION @TargetDlgHandle
		MESSAGE TYPE
		[//Marketing/SB/ReplyMessage]
		(@ReplyMessage);
		END CONVERSATION @TargetDlgHandle;  -- ��������� ������ 
	END 
	
	SELECT @ReplyMessage AS SentReplyMessage; 

	COMMIT TRAN;
END


--7. ��������� ������������ ������, ������� � GetNewReport: �������� ����� �� ��������� ������������� ��������� �� ������
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

--8.��������� ��������� �� �������-����������� (������������ ������  "Message received" �� ���������� � ��������� ������)

CREATE PROCEDURE ConfirmReport
AS
BEGIN
	--Receiving Reply Message from the Target.	
	DECLARE @InitiatorReplyDlgHandle UNIQUEIDENTIFIER,
			@ReplyReceivedMessage NVARCHAR(1000) 
	
	BEGIN TRAN; 
	--�������� ��������� (��� ��� ����������), ��������� ������, � ��������� ����������
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
--���� ������ STATUS = OFF - � ������� ������ ������ ��������
-- ACTIVATION (   STATUS = ON - ������ ��������� ��������, ��� ��� ���������� ��������� � �������, ����� ����������� ��������� ��������� PROCEDURE_NAME = Sales.ConfirmInvoice
--�.�. ���� ��������� ��������� ���������
--MAX_QUEUE_READERS - �� 1 �� 32000 - ������� �������� ����� ������������ �������
--POISON_MESSAGE_HANDLING  - ����� ���������� �������, ���� ����� �������� ���������, ������� �� ���������� ����������, ����� �������-�� �������
ALTER QUEUE [dbo].[MarketingInitiatorQueue] WITH STATUS = ON , RETENTION = OFF , POISON_MESSAGE_HANDLING (STATUS = OFF) 
	, ACTIVATION (   STATUS = OFF,
        PROCEDURE_NAME = dbo.ConfirmReport, MAX_QUEUE_READERS = 1, EXECUTE AS OWNER) ; 

GO
ALTER QUEUE [dbo].[MarketingTargetQueue] WITH STATUS = ON , RETENTION = OFF , POISON_MESSAGE_HANDLING (STATUS = OFF)
	, ACTIVATION (  STATUS = OFF,
        PROCEDURE_NAME = dbo.GetNewReport, MAX_QUEUE_READERS = 1, EXECUTE AS OWNER) ; 

GO

--10.��������� ���� �������

-- ���������� ����� ��� ������ ������ 1005
SELECT * FROM BulkReport WHERE BulkReportsID = 1005;

--��������� ��������� � BulkReportsID = 1005 � ������� MarketingTargetQueue.
--����� ���������, ��������, � ����� ��������� ��������� ������� - ������ �������, ���������� � ����������� ��� � �������, ����� �� ����� �� ����������
EXEC SendNewReport @ReportId = 1005;

--������� �� �������:
SELECT CAST(message_body AS XML),*
FROM dbo.MarketingTargetQueue;

SELECT CAST(message_body AS XML),*
FROM dbo.MarketingInitiatorQueue;

--��������� � ���������
EXEC GetNewReport;
SELECT * FROM BulkReport WHERE BulkReportsID = 1005;
SELECT * FROM BulkReportResult   WHERE BulkReportsID = 1005;
--Initiator
EXEC dbo.ConfirmReport;

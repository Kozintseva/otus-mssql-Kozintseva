/* демонстрация создания смс-рассылки */

USE Marketing

--1. Создание смс-рассылки - пользователь задает параметры рассылки:
	CREATE  or ALTER    PROCEDURE  [dbo].[CreateNewBulkSms]
	@name nvarchar(250),     -- имя рассылки
	@DateStart datetime,     -- дата начания рассылки
	@DateFinish datetime,    -- дата окончания рассылки
	@message nvarchar(max),  -- текст смс
	@product nvarchar(50),   -- продукт, по которому будет рассылка
	@user int                -- передается ID пользователя, кто создает рассылку
    AS
	
	 
	insert into BulkSMS  ([BulkSmsId],[Name],[StartSend],[EndSend],[StatusId] ,[MessageText],[ProductId],[CreatedbyId],[CreatedOn])
	VALUES (next value for sequences.OwnerID_seq, @name, @DateStart, @DateFinish, 0, @message, (select productId from dbo.Product where ProductName=@product) , @user, getdate());
	
	
     GO


--2.  Добавление аудитории смс-рассылки:


	CREATE  OR  ALTER    PROCEDURE  [dbo].[CreateNewBulkSmsTarget]
	@ClientId int,
	@BulkSmsId int

    AS
	INSERT INTO [dbo].[SmsTarget] ([SmsTargetId] ,[ClientId],[BulkSmsId],[StatusId] ,[DestPhone])
     VALUES (next value for sequences.ownerid_seq, @ClientId, 0, @BulkSmsId, (select contact from dbo.Contacts where ClientId=@ClientID and typeContact=1))
	
    GO

--3. формирование смс:
CREATE OR ALTER PROCEDURE [dbo].[GetSms]
       @BulkSmsId int,
       @ContactId uniqueidentifier,
       @SmsText nvarchar(max) OUT

as

BEGIN

       declare @ContactRId bigint = (select Rid from Contact where id = @ContactId),

       @MessageText nvarchar(max) = (select a.MessageText from BulkSMS a where Id = @BulkSmsId)

       create table #Contact (
             ContactId int primary key,
             [Sequence] bigint,
             Phone nvarchar(20),
             MessageText nvarchar(max),
             MessageLength int default 0,
             IsCyrillic bit default 0,
             TsiSmsCostId uniqueidentifier,
             IsSent bit,
             TsiCost numeric(15, 2),
             SmsCount int default 0
       )

       insert #Contact(RId, MessageText)

             VALUES (@ContactRId, @MessageText) --@ContactId

       exec CalcBulkSmsCount  

       select @SmsText = a.MessageText from #Contact a

END

GO

--4. подсчет кол-ва смс, исходя из текста сообщения
CREATE OR ALTER PROCEDURE [dbo].[CalcBulkSmsCount]
       @MessageText nvarchar(max)
AS

BEGIN
       set nocount on;
       if (object_id('tempdb..#Contact') is null)
       begin

            create table #Contact (
             ContactId int primary key,
             [Sequence] bigint,
             Phone nvarchar(20),
             MessageText nvarchar(max),
             MessageLength int default 0,
             IsCyrillic bit default 0,
             TsiSmsCostId uniqueidentifier,
             IsSent bit,
             TsiCost numeric(15, 2),
             SmsCount int default 0
       )

       end

       if (@MessageText like N'%[А-я]%')

       begin
             update #Contact set IsCyrillic = 1,  SmsCount = case when MessageLength <= 70 then 1 else floor(MessageLength / 63) + 1 end
       end

       else begin

             update #Contact  
			 set IsCyrillic = 1  where MessageText like N'%[А-я]%'
			 
			 update t   
			 set SmsCount = case when MessageLength <= 70 then 1 else floor(MessageLength / 63) + 1 end
             from #Contact t
             where t.IsCyrillic = 1

             update t
             set SmsCount = case when MessageLength <= 160 then 1 else floor(MessageLength / 145) + 1 end
             from #Contact t
             where t.IsCyrillic = 0
       end
END;

GO

 

 
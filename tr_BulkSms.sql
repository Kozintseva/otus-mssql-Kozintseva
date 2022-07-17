--1. вставка записи в  BulkEvent и BulkEventHistory после инсерта в BulkSms
CREATE OR ALTER TRIGGER Tr_insertBulkSms
ON BulkSms
AFTER INSERT 

AS

INSERT INTO [dbo].[BulkEvent] ([EventId] ,[CreatedOn] ,[CreatedUser] ,[ChangedOn] ,[ChangedUser] ,[Module])
SELECT BulkSmsId , getdate(), CreatedbyId , getdate(), CreatedbyId, 'sms_module'  
FROM INSERTED;

INSERT INTO [dbo].[BulkEventHistory] ([EventHId] ,[EventId] ,[ChangedOn] ,[UserId],[OperCode] ,[StatusOld] ,[StatusNew] ,[Comment])
SELECT next value for sequences.ownerid_seq, BulkSmsId,  getdate(), CreatedbyId, 'create' , NULL ,'new', NULL
FROM INSERTED;
          

--2.вставка записи в  BulkEventHistory после апдейта в BulkSms
CREATE OR ALTER TRIGGER Tr_insertBulkSms
ON BulkSms
AFTER UPDATE 
AS

UPDATE [dbo].[BulkEvent]  SET ChangedOn=getdate() 
FROM INSERTED i where eventId=i.BulkSmsId;

INSERT INTO [dbo].[BulkEventHistory] ([EventHId] ,[EventId] ,[ChangedOn] ,[UserId],[OperCode] ,[StatusOld] ,[StatusNew] ,[Comment])
SELECT next value for sequences.ownerid_seq, i.BulkSmsId,  getdate(), i.CreatedbyId, 'change' , case when d.StatusId=0 then 'new' 
                                                                                                     when d.StatusId=1 then 'send' 
																									 when d.StatusId=6 then 'end'  
																									 when d.StatusId=10 then 'cancel' 
																									 when d.StatusId=22 then 'error' else '' end  ,
																								case when i.StatusId=0 then 'new' 
																									 when i.StatusId=1 then 'send' 
																									 when i.StatusId=6 then 'end'  
																									 when i.StatusId=10 then 'cancel' 
																									 when i.StatusId=22 then 'error' else '' end  , 
																								NULL
FROM INSERTED i
INNER JOIN DELETED d ON i.BulkSmsId = d.BulkSmsId;
          
GO
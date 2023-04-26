create table [DatabaseRestore].[OverWriteToken](
	[OverWriteTokenID] [int] identity(1,1) not null,
	[DatabaseName] [varchar](256) not null,
	[OverWriteToken] [uniqueidentifier] not null,
 constraint [PK_OverWriteTokenID] primary key clustered ( [OverWriteTokenID] asc )
);

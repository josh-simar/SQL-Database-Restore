IF NOT EXISTS(SELECT * FROM sys.objects o INNER JOIN sys.schemas s ON o.schema_id=s.schema_id WHERE o.name = 'RestorePermissions' AND s.name = 'DatabaseRestore' AND type = 'P')
	EXEC( 'CREATE PROCEDURE [DatabaseRestore].[RestorePermissions] AS SELECT dt = GETDATE()' )
GO

/****** Object:  StoredProcedure [DatabaseRestore].[RestorePermissions]    Script Date: 8/3/2017 10:54:45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER PROCEDURE [DatabaseRestore].[RestorePermissions]
    @bDebug       BIT = 0,
    @DatabaseName VARCHAR(512)
AS
	SET NOCOUNT ON
    DECLARE @tsql AS NVARCHAR(MAX)
        = 'USE ' + @DatabaseName
          + '
SELECT CASE
           WHEN [sp].[name] IS NULL THEN
               ''PRINT ''''/****************Cannot setup '' + [dp].[name]
               + '' because it doesn''''''''t exist at the server level****************/'''''' + CHAR(13)
           ELSE
               ''USE '               + @DatabaseName
          + '; ALTER USER '' + QUOTENAME([dp].[name]) + '' WITH LOGIN = '' + QUOTENAME([dp].[name]) + '';'' + CHAR(13)
       END
FROM [sys].[database_principals] [dp]
    LEFT JOIN [sys].[server_principals] [sp]
        ON [dp].[name] = [sp].[name]
WHERE [dp].[type] = ''S''
      AND [dp].[authentication_type] = 1
      AND [dp].[sid] != 0x01;
';

    DECLARE @table AS TABLE (va VARCHAR(1000));
    INSERT INTO @table
    EXECUTE sp_executesql
        @Query = @tsql;

    DECLARE @vsql AS VARCHAR(MAX);
    SET @vsql = '';
    SELECT
        @vsql += va
    FROM
        @table;
	IF @bDebug = 1
		PRINT @vsql;
    
	EXEC (@vsql);
	
    IF @bDebug = 1
        PRINT @vsql;

    EXEC (@vsql);

    SELECT
        @vsql = '';

    SELECT
        @vsql = 'USE ' + @DatabaseName + CHAR(10);
    SELECT
        @vsql
        = @vsql + 'IF NOT EXISTS (SELECT [DP].[name] FROM sys.database_principals [dp] WHERE [dp].name = '''
          + [DP].[PrincipalName] + ''')
BEGIN
	CREATE USER ' + QUOTENAME([DP].[PrincipalName]) + ' FOR LOGIN ' + QUOTENAME([DP].[PrincipalName])
          + '
	ALTER USER ' + QUOTENAME([DP].[PrincipalName]) + ' WITH DEFAULT_SCHEMA=[dbo]
END
ALTER ROLE '    + [DP].[RoleMembership] + ' ADD MEMBER ' + QUOTENAME([DP].[PrincipalName])
    FROM
        [DatabaseRestore].[Permisions] [DP]
    WHERE
        [DP].[DatabaseName] = @DatabaseName;

    IF @bDebug = 1
        PRINT @vsql;
    ELSE
        BEGIN
            EXECUTE (@vsql);
            PRINT 'Database Permissions Restored';
        END;

    SELECT
        @vsql = 'USE ' + @DatabaseName + CHAR(10);
    SELECT
        @vsql
        = @vsql + 'IF NOT EXISTS (SELECT [dp].[name] FROM sys.database_principals [dp] WHERE [dp].[name] = '''
          + [DPS].[PrincipalName] + ''')
BEGIN
	IF EXISTS (SELECT [sp].[name] FROM sys.server_principals [sp] WHERE [sp].[name] = '''
		+ [DPS].[PrincipalName] + ''')
	CREATE USER ' + QUOTENAME([DPS].[PrincipalName]) + ' FOR LOGIN ' + QUOTENAME([DPS].[PrincipalName]) + '
END'            + CHAR(10) + [DPS].[SpecialPermissionExecuteStatement]
    FROM
        [DatabaseRestore].[SpecialPermisions] [DPS]
    WHERE
        [DPS].[DatabaseName] = @DatabaseName;

    IF @bDebug = 1
        PRINT @vsql;
    ELSE
        BEGIN
            EXECUTE (@vsql);
            PRINT 'Database Special Permissions Restored';
        END;

    RETURN;

GO


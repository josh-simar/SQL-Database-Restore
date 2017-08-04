IF NOT EXISTS(SELECT * FROM sys.objects o INNER JOIN sys.schemas s ON o.schema_id=s.schema_id WHERE o.name = 'usp_SetCompatibilityLevel' AND s.name = 'DatabaseRestore' AND type = 'P')
	EXEC( 'CREATE PROCEDURE [DatabaseRestore].[usp_SetCompatibilityLevel] AS SELECT dt = GETDATE()' )
GO

/****** Object:  StoredProcedure [DatabaseRestore].[usp_SetCompatibilityLevel]    Script Date: 8/3/2017 11:01:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [DatabaseRestore].[usp_SetCompatibilityLevel]
	@bDebug BIT = 0
  , @DatabaseName VARCHAR(500)
AS
	BEGIN
		SET NOCOUNT ON;
		DECLARE @fullproductnumber AS NVARCHAR(128)
			, @fullversionnumberdelimeter AS CHAR(1) = '.'
			, @fullversionnumberdelimetercharnumber AS TINYINT
			, @compatibility_levelText NVARCHAR(128)
			, @compatibility_level SMALLINT;

		SELECT @fullproductnumber = CONVERT(NVARCHAR(128), SERVERPROPERTY('ProductVersion'))
		SELECT @fullversionnumberdelimetercharnumber = CHARINDEX('.',@fullproductnumber)		
		SELECT @compatibility_levelText = LEFT(@fullproductnumber,@fullversionnumberdelimetercharnumber - 1)
		SELECT @compatibility_level = CAST(@compatibility_levelText AS INT) * 10;

		DECLARE	@sql AS NVARCHAR(MAX);
		SELECT
			@sql = 'USE ' + QUOTENAME(@DatabaseName) + CHAR(13);
		SELECT
			@sql = @sql + 'ALTER DATABASE ' + QUOTENAME(@DatabaseName)
			+ ' SET COMPATIBILITY_LEVEL = '
			+ CAST(@compatibility_level AS NVARCHAR(4));

		IF @bDebug = 1
			PRINT @sql
		ELSE
			EXECUTE [sp_executesql] @sql;

	END;

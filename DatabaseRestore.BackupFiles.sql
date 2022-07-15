IF NOT EXISTS(SELECT * FROM sys.objects o INNER JOIN sys.schemas s ON o.schema_id=s.schema_id WHERE o.name = 'BackupFiles' AND s.name = 'DatabaseRestore' AND type = 'P')
	EXEC( 'CREATE PROCEDURE [DatabaseRestore].[BackupFiles] AS SELECT dt = GETDATE()' )
GO


/****** Object:  StoredProcedure [DatabaseRestore].[BackupFiles]    Script Date: 8/3/2017 9:28:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [DatabaseRestore].[BackupFiles]
	@bDebug BIT = 0
  , @DirectoryToScan AS VARCHAR(500) --= '\\firstfolder\sub-folder'
  , @FilesToScan AS VARCHAR(500) --= 'DatabaseName_Full'
  , @AllFiles AS [NVARCHAR](MAX) OUTPUT
  , @ErrorOccured AS [BIT] OUTPUT
AS
	DECLARE	@FolderCommand AS [VARCHAR](200);
	DECLARE	@FullCommand AS [VARCHAR](200);
	DECLARE	@xpCmdShellOnBegin AS [BIT];
	DECLARE	@AdvancedOptionsOnBegin AS [BIT];
	DECLARE @FileDate AS VARCHAR(30);
	DECLARE @FileTime AS VARCHAR(30);

	SELECT
		@FolderCommand = 'IF NOT EXIST ' + @DirectoryToScan
		+ ' ECHO Folder Doesn''t Exist'
	  , @FullCommand = 'dir ' + @DirectoryToScan + @FilesToScan;

	SET @AdvancedOptionsOnBegin = (
									SELECT
										CAST([c].[value] AS BIT)
									FROM
										[sys].[configurations] [c]
									WHERE
										[c].[name] = 'show advanced options'
								  );

-- TO allow advanced options TO be changed.

	SET @xpCmdShellOnBegin = (
							   SELECT
								CAST([c].[value] AS BIT)
							   FROM
								[sys].[configurations] [c]
							   WHERE
								[c].[name] = 'xp_cmdshell'
							 );

	IF ( @xpCmdShellOnBegin = 0
		 AND @xpCmdShellOnBegin = 0
	   )
		BEGIN
			EXEC [sp_configure] 'show advanced options', 1;
	 
	-- TO update the currently configured value for advanced options.
			RECONFIGURE WITH OVERRIDE;
		END;

	IF @xpCmdShellOnBegin = 0
		BEGIN

	-- TO disable the feature.
			EXEC [sp_configure] 'xp_cmdshell', 1;

	-- TO update the currently configured value for advanced options.
			RECONFIGURE WITH OVERRIDE;
		END;

-- ************************************************************************************************************

	CREATE TABLE [#FolderExists] ( [Value] VARCHAR(50) );

	INSERT	INTO [#FolderExists]
			EXEC [xp_cmdshell] @FolderCommand;

	CREATE TABLE [#Files] ( [Name] [VARCHAR](500) );

	INSERT	INTO [#Files]
			EXEC [xp_cmdshell] @FullCommand;

	IF @xpCmdShellOnBegin = 0 --Turn it back off if it was off originally
		BEGIN

	-- TO disable the feature.
			EXEC [sp_configure] 'xp_cmdshell', 0;

	-- TO update the currently configured value for this feature.
			RECONFIGURE WITH OVERRIDE;

		END;

	IF @AdvancedOptionsOnBegin = 0
		BEGIN
		-- TO do not allow advanced options TO be changed.
			EXEC [sp_configure] 'show advanced options', 0;

	-- TO update the currently configured value for advanced options.
			RECONFIGURE WITH OVERRIDE;
		END;

	IF (
		 SELECT
			[FE].[Value]
		 FROM
			[#FolderExists] [FE]
		 WHERE
			[FE].[Value] = 'Folder Doesn''t Exist'
	   ) IS NOT NULL
		BEGIN
			SELECT
				@AllFiles = 'The folder as specified does not exist';
			SELECT
				@ErrorOccured = 1;
			RETURN;
		END;

	IF (
		 SELECT
			[F].[Name]
		 FROM
			[#Files] [F]
		 WHERE
			[F].[Name] = 'File Not Found'
	   ) IS NOT NULL
		BEGIN
			SELECT
				@AllFiles = 'The file(s) as specified do not exist';
			SELECT
				@ErrorOccured = 1;
			RETURN;
		END;

	SELECT
		[F].[Name]
	  , [FileName] = REVERSE(SUBSTRING(REVERSE([F].[Name]), 0,
									   CHARINDEX(' ', REVERSE([F].[Name]))))
	  , [FileDate] = SUBSTRING([F].[Name], 0, CHARINDEX(' ', [F].[Name]))
	  , [FileTime] = SUBSTRING([F].[Name], CHARINDEX(' ', [F].[Name]) + 1,
							   CHARINDEX(' ', [F].[Name], CHARINDEX(' ', [F].[Name]) + 1))
	INTO
		[#Files2]
	FROM
		[#Files] [F]
	WHERE
		ISNUMERIC(LEFT([F].[Name], 1)) = 1
	ORDER BY
		CAST(LEFT([F].[Name], 17) AS DATETIME) DESC;

	IF @bDebug = 1
		SELECT
			[F2].[Name]
		  , [F2].[FileName]
		  , [F2].[FileDate]
		  , [F2].[FileTime]
		FROM
			[#Files2] [F2];

	SELECT
		  @FileDate = (SELECT MAX([F2].[FileDate]) FROM [#Files2] [F2])
	SELECT
		  @FileTime = (SELECT TOP (1) [F2].[FileTime] FROM [#Files2] [F2] WHERE [F2].[FileDate] = @FileDate ORDER BY CAST(F2.FileTime AS TIME) DESC)

	SELECT
		@AllFiles = STUFF((
							SELECT
								', DISK  = ''' + @DirectoryToScan + [F2].[FileName]
								+ ''''
							FROM
								[#Files2] [F2]
							WHERE
								[F2].[FileDate] = @FileDate
								AND [F2].[FileTime] = @FileTime
							ORDER BY
								[F2].[FileName]
						  FOR
							XML	PATH('')
						  ), 1, 2, '');

	PRINT 'Using backup taken on ' + @FileDate + ' At ' + @FileTime

	IF @bDebug = 1
		SELECT
			@AllFiles;

	RETURN;


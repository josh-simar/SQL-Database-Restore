IF NOT EXISTS(SELECT * FROM sys.objects o INNER JOIN sys.schemas s ON o.schema_id=s.schema_id WHERE o.name = 'MainRestore' AND s.name = 'DatabaseRestore' AND type = 'P')
	EXEC( 'CREATE PROCEDURE [DatabaseRestore].[MainRestore] AS SELECT dt = GETDATE()' )
GO


/****** Object:  StoredProcedure [DatabaseRestore].[MainRestore]    Script Date: 8/3/2017 10:48:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [DatabaseRestore].[MainRestore]
	@bDebug BIT = 0
  , @bDWDrives BIT
  , @AllFiles AS NVARCHAR(MAX) = NULL
  , @DatabaseName AS VARCHAR(500)
  , @FilesToUnpack AS VARCHAR(MAX) = ''
  , @DirectoryToScan AS VARCHAR(500)
  , @FilesToScan AS VARCHAR(500)
  , @bFinal BIT = 1
  , @Diff BIT = 0
  , @DWOverride BIT = 0
  , @OverWrite UNIQUEIDENTIFIER = NULL
AS
	SET NOCOUNT ON;

	DECLARE	@ErrorOccured AS BIT;

	IF @bDWDrives = 1
		AND @DatabaseName NOT LIKE '%DW%'
		AND @DWOverride = 0
		BEGIN
			PRINT 'You have specified what looks to be a non-DW database on DW drives';
			PRINT 'If this is correct please modify your execution to include @DWOverride=1';
			RETURN;
		END;

	IF @bDWDrives = 0
		AND @DatabaseName LIKE '%DW%'
		AND @DWOverride = 0
		BEGIN
			PRINT 'You have specified what looks to be a DW database on non-DW drives';
			PRINT 'If this is correct please modify your execution to include @DWOverride=1';
			RETURN;
		END;

	IF LEFT(REVERSE(@DirectoryToScan), 1) != '\'
		SELECT
			@DirectoryToScan += '\';

	IF LEFT(REVERSE(@FilesToScan), 3) != '*.*'
		SELECT
			@FilesToScan += '*.*';

	IF @AllFiles IS NULL
		BEGIN
			PRINT 'Finding Backup Files.';
			EXECUTE [DatabaseRestore].[BackupFiles] @bDebug = @bDebug,
				@DirectoryToScan = @DirectoryToScan,
				@FilesToScan = @FilesToScan, @AllFiles = @AllFiles OUTPUT,
				@ErrorOccured = @ErrorOccured OUTPUT;
		END;

	IF @ErrorOccured = 1
		BEGIN
			PRINT 'Could not find files with specified parameters.';
			PRINT 'Please check your inputs and try again';
			PRINT @AllFiles;
			RETURN;
		END;

	IF @Diff = 0
		BEGIN
			IF @FilesToUnpack = ''
				BEGIN
					PRINT 'Finding what the files are that need to be unpacked.';
					EXECUTE [DatabaseRestore].[FilesToUnpack] @bDebug = @bDebug,
						@bDWDrives = @bDWDrives, @AllFiles = @AllFiles,
						@DatabaseName = @DatabaseName,
						@vFilesToUnpack = @FilesToUnpack OUTPUT,
						@ErrorOccured = @ErrorOccured OUTPUT;
				END;
		END;

	IF @ErrorOccured = 1
		RETURN;

	DECLARE	@vRestoreCommand AS VARCHAR(MAX);

	SELECT
		@vRestoreCommand = 'RESTORE DATABASE' + CHAR(10) + CHAR(9)
		+ QUOTENAME(@DatabaseName) + CHAR(10) + 'FROM' + CHAR(10) + CHAR(9)
		+ @AllFiles + CHAR(10) + 'WITH FILE = 1,' + CHAR(10);

	IF @Diff = 0
		SELECT
			@vRestoreCommand += @FilesToUnpack + CHAR(10);

	SELECT
		@vRestoreCommand += ', NOUNLOAD' + CHAR(10);
	
	IF DB_ID(@DatabaseName) IS NOT NULL
		AND @Diff != 1
		AND (
			  SELECT
				[OWT].[DatabaseName]
			  FROM
				[DatabaseRestore].[OverWriteToken] [OWT]
			  WHERE
				@DatabaseName = [OWT].[DatabaseName]
				AND @OverWrite = [OWT].[OverWriteToken]
			) IS NOT NULL
		SELECT
			@vRestoreCommand += ', REPLACE' + CHAR(10);
	ELSE
		BEGIN
			IF DB_ID(@DatabaseName) IS NOT NULL
				BEGIN
					IF (
						 SELECT
							[OWT].[DatabaseName]
						 FROM
							[DatabaseRestore].[OverWriteToken] [OWT]
						 WHERE
							@DatabaseName = [OWT].[DatabaseName]
					   ) IS NOT NULL
						UPDATE
							[OWT]
						SET	
							[OverWriteToken] = NEWID()
						FROM
							[DatabaseRestore].[OverWriteToken] [OWT]
						WHERE
							[OWT].[DatabaseName] = @DatabaseName;
					ELSE
						INSERT	INTO [DatabaseRestore].[OverWriteToken]
								( [DatabaseName]
								, [OverWriteToken]
								)
						VALUES
								( @DatabaseName
								, NEWID()
								);
				
					SELECT
						@OverWrite = [OWT].[OverWriteToken]
					FROM
						[DatabaseRestore].[OverWriteToken] [OWT]
					WHERE
						@DatabaseName = [OWT].[DatabaseName];
				  

					PRINT 'You are trying to overwrite a database without using an overwrite token';
					PRINT 'If this was your intent to overwrite the database please re-run the command';
					PRINT 'and modify your execution to include ,@OverWrite='''
						+ CAST(@OverWrite AS VARCHAR(40)) + '''';

					RETURN;
				END;
		END;

	SELECT
		@vRestoreCommand += ', STATS = 100' + CHAR(10)
		+ ', BUFFERCOUNT = 2200' + CHAR(10);

	IF ( @bFinal = 0 )
		SELECT
			@vRestoreCommand += ', NORECOVERY' + CHAR(10);
	ELSE
		SELECT
			@vRestoreCommand += ', RECOVERY' + CHAR(10);

	IF @bDebug = 1
		BEGIN
			PRINT @vRestoreCommand;
		END;

	EXECUTE (@vRestoreCommand);

	IF ( @bFinal = 1 )
		BEGIN
			EXECUTE [DatabaseRestore].[CorrectOwner] @bDebug = @bDebug,
				@DatabaseName = @DatabaseName;

			EXECUTE [DatabaseRestore].[RestoreRole] @bDebug = @bDebug,
				@DatabaseName = @DatabaseName;

			EXECUTE [DatabaseRestore].[RestorePermissions] @bDebug = @bDebug,
				@DatabaseName = @DatabaseName;

			EXECUTE [DatabaseRestore].[usp_SetCompatibilityLevel] @bDebug = @bDebug,
				@DatabaseName = @DatabaseName;

			DELETE
				[OWT]
			FROM
				[DatabaseRestore].[OverWriteToken] [OWT]
			WHERE
				[OWT].[DatabaseName] = @DatabaseName;

		END;

	RETURN;

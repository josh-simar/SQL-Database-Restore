IF NOT EXISTS(SELECT * FROM sys.objects o INNER JOIN sys.schemas s ON o.schema_id=s.schema_id WHERE o.name = 'FilesToUnpack' AND s.name = 'DatabaseRestore' AND type = 'P')
	EXEC( 'CREATE PROCEDURE [DatabaseRestore].[FilesToUnpack] AS SELECT dt = GETDATE()' )
GO

/****** Object:  StoredProcedure [DatabaseRestore].[FilesToUnpack]    Script Date: 8/3/2017 10:35:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [DatabaseRestore].[FilesToUnpack]
	@bDebug BIT = 0
  , @bDWDrives BIT
  , @AllFiles AS [NVARCHAR](MAX)
  , @DatabaseName AS VARCHAR(500)
  , @vFilesToUnpack VARCHAR(MAX) OUTPUT
  , @ErrorOccured BIT OUTPUT
AS
	SET NOCOUNT ON;
	CREATE TABLE [#UnpackedFiles]
		(
		  [ID] INT IDENTITY(1, 1)
		, [LogicalName] NVARCHAR(128)
		, [PhysicalName] NVARCHAR(260)
		, [Type] NCHAR(1)
		, [FileGroupName] NVARCHAR(128)
		, [Size] BIGINT
		, [MaxSize] BIGINT
		, [FileId] BIGINT
		, [CreateLSN] DECIMAL(25, 0)
		, [DropLSN] DECIMAL(25, 0)
		, [UniqueId] UNIQUEIDENTIFIER
		, [ReadOnlyLSN] DECIMAL(25, 0)
		, [ReadWriteLSN] DECIMAL(25, 0)
		, [BackupSizeInBytes] BIGINT
		, [SourceBlockSize] INT
		, [FileGroupId] INT
		, [LogGroupGUID] UNIQUEIDENTIFIER
		, [DifferentialBaseLSN] DECIMAL(25, 0)
		, [DifferentialBaseGUID] UNIQUEIDENTIFIER
		, [IsReadOnly] BIT
		, [IsPresent] BIT
		, [TDEThumbprint] VARBINARY(20)
		);

	CREATE TABLE [#UnpackedFiles2]
		(
		  [ID] INT
		, [LogicalName] NVARCHAR(128)
		, [PhysicalName] NVARCHAR(260)
		, [Type] NCHAR(1)
		, [FileGroupName] NVARCHAR(128)
		, [Size] BIGINT
		, [MaxSize] BIGINT
		, [FileId] BIGINT
		, [CreateLSN] DECIMAL(25, 0)
		, [DropLSN] DECIMAL(25, 0)
		, [UniqueId] UNIQUEIDENTIFIER
		, [ReadOnlyLSN] DECIMAL(25, 0)
		, [ReadWriteLSN] DECIMAL(25, 0)
		, [BackupSizeInBytes] BIGINT
		, [SourceBlockSize] INT
		, [FileGroupId] INT
		, [LogGroupGUID] UNIQUEIDENTIFIER
		, [DifferentialBaseLSN] DECIMAL(25, 0)
		, [DifferentialBaseGUID] UNIQUEIDENTIFIER
		, [IsReadOnly] BIT
		, [IsPresent] BIT
		, [TDEThumbprint] VARBINARY(20)
		, [NewDriveLetter] CHAR(1)
		);

	INSERT	INTO [#UnpackedFiles]
			EXEC ( 'RESTORE FILELISTONLY
	FROM ' + @AllFiles + ';'
				);

	DECLARE	@nDrives AS TINYINT;

	CREATE TABLE [#AllDrivesSpace]
		(
		  [ID] INT IDENTITY(1, 1)
				   NOT NULL
		, [drive] NVARCHAR(1)
		, [MB free] INT
		);

	INSERT	INTO [#AllDrivesSpace]
			( [drive]
			, [MB free]
			)
			EXECUTE [master].[dbo].[xp_fixeddrives];

	CREATE TABLE [#Drives]
		(
		  [ID] INT IDENTITY(1, 1)
		, [DriveLetter] CHAR(1)
		, [MB free] INT
		);

	IF @bDWDrives = 1
		BEGIN
			INSERT	INTO [#Drives]
			SELECT
				[D].[DriveLetter]
			  , [ADS].[MB free]
			FROM
				[DatabaseRestore].[Drives] [D]
				INNER JOIN [#AllDrivesSpace] [ADS]
					ON [D].[DriveLetter] = [ADS].[drive]
			WHERE
				[D].[DriveType] = 'DW';
		END;
	ELSE
		BEGIN
			INSERT	INTO [#Drives]
			SELECT
				[D].[DriveLetter]
			  , [ADS].[MB free]
			FROM
				[DatabaseRestore].[Drives] [D]
				INNER JOIN [#AllDrivesSpace] [ADS]
					ON [D].[DriveLetter] = [ADS].[drive]
			WHERE
				[D].[DriveType] = 'NORMAL';
		END;

	SELECT
		@nDrives = (
					 SELECT
						COUNT(*)
					 FROM
						[#Drives]
				   );
	IF @bDebug = 1
		BEGIN
			PRINT @nDrives;
			SELECT
				[D].[ID]
			  , [D].[DriveLetter]
			  , [D].[MB free]
			FROM
				[#Drives] [D];
		END;

	INSERT	INTO [#UnpackedFiles2]
	SELECT
		[UPF].[ID]
	  , [UPF].[LogicalName]
	  , [UPF].[PhysicalName]
	  , [UPF].[Type]
	  , [UPF].[FileGroupName]
	  , [UPF].[Size]
	  , [UPF].[MaxSize]
	  , [UPF].[FileId]
	  , [UPF].[CreateLSN]
	  , [UPF].[DropLSN]
	  , [UPF].[UniqueId]
	  , [UPF].[ReadOnlyLSN]
	  , [UPF].[ReadWriteLSN]
	  , [UPF].[BackupSizeInBytes]
	  , [UPF].[SourceBlockSize]
	  , [UPF].[FileGroupId]
	  , [UPF].[LogGroupGUID]
	  , [UPF].[DifferentialBaseLSN]
	  , [UPF].[DifferentialBaseGUID]
	  , [UPF].[IsReadOnly]
	  , [UPF].[IsPresent]
	  , [UPF].[TDEThumbprint]
	  , [NewDriveLetter] = (
							 SELECT
								[D].[DriveLetter]
							 FROM
								[#Drives] [D]
							 WHERE
								[D].[ID] = ( [UPF].[ID] % @nDrives ) + 1
						   )
	FROM
		[#UnpackedFiles] [UPF]
	WHERE
		[UPF].[Type] = 'D';

	IF @bDebug = 1
		SELECT
			[UPF2].[ID]
		  , [UPF2].[LogicalName]
		  , [UPF2].[PhysicalName]
		  , [UPF2].[Type]
		  , [UPF2].[FileGroupName]
		  , [UPF2].[Size]
		  , [UPF2].[MaxSize]
		  , [UPF2].[FileId]
		  , [UPF2].[CreateLSN]
		  , [UPF2].[DropLSN]
		  , [UPF2].[UniqueId]
		  , [UPF2].[ReadOnlyLSN]
		  , [UPF2].[ReadWriteLSN]
		  , [UPF2].[BackupSizeInBytes]
		  , [UPF2].[SourceBlockSize]
		  , [UPF2].[FileGroupId]
		  , [UPF2].[LogGroupGUID]
		  , [UPF2].[DifferentialBaseLSN]
		  , [UPF2].[DifferentialBaseGUID]
		  , [UPF2].[IsReadOnly]
		  , [UPF2].[IsPresent]
		  , [UPF2].[TDEThumbprint]
		  , [UPF2].[NewDriveLetter]
		FROM
			[#UnpackedFiles2] [UPF2];

	SELECT
		[DriveLetter] = LEFT([mf].[physical_name], 1)
	  , [CurrentSize] = SUM(CAST([mf].[size] AS BIGINT)) * 1024
	INTO
		[#Current]
	FROM
		[sys].[master_files] [mf]
		INNER JOIN [sys].[databases] [d]
			ON [mf].[database_id] = [d].[database_id]
	WHERE
		[mf].[type] = 0
		AND [d].[name] = @DatabaseName
	GROUP BY
		[d].[name]
	  , LEFT([mf].[physical_name], 1);

	SELECT
		[D].[DriveLetter]
	  , [TotalFileSize] = ( SUM([UPF2].[Size]) - ISNULL([C].[CurrentSize], 0) )
	  , [Bytes Free] = CAST([D].[MB free] AS BIGINT) * 1048576
	INTO
		[#DriveSpace]
	FROM
		[#UnpackedFiles2] [UPF2]
		INNER JOIN [#Drives] [D]
			ON [UPF2].[NewDriveLetter] = [D].[DriveLetter]
		LEFT JOIN [#Current] [C]
			ON [C].[DriveLetter] = [D].[DriveLetter]
	GROUP BY
		[D].[DriveLetter]
	  , [D].[MB free]
	  , [C].[CurrentSize];

	IF @bDebug = 1
		BEGIN
			SELECT
				[C].[DriveLetter]
			  , [C].[size]
			  , [C].[CurrentSize]
			FROM
				[#Current] [C];
			SELECT
				[DS].[DriveLetter]
			  , [DS].[CurrentSize]
			  , [DS].[TotalFileSize]
			  , [DS].[Bytes Free]
			FROM
				[#DriveSpace] [DS];
		END;

	IF (
		 SELECT TOP 1
			[A] = 'A'
		 FROM
			[#DriveSpace] [DS]
		 WHERE
			[DS].[Bytes Free] < [DS].[TotalFileSize]
	   ) IS NOT NULL
		BEGIN
			PRINT 'This database is too big to be restored. Please cleanup the drives and try again';
			DECLARE	@vPrintWhatsWrong AS VARCHAR(MAX) = '';

			SELECT
				@vPrintWhatsWrong = @vPrintWhatsWrong + 'Drive '
				+ [DS].[DriveLetter] + ' has '
				+ REPLACE(CONVERT(VARCHAR, CAST([DS].[Bytes Free] AS MONEY), 1),
						  '.00', '') + ' Bytes Free and needs '
				+ REPLACE(CONVERT(VARCHAR, CAST([DS].[TotalFileSize] AS MONEY), 1),
						  '.00', '') + ' Free to complete this restore'
				+ CHAR(13) + CHAR(10)
			FROM
				[#DriveSpace] [DS]
			WHERE
				[DS].[Bytes Free] < [DS].[TotalFileSize];

			PRINT @vPrintWhatsWrong;

			SELECT
				@ErrorOccured = 1;
			RETURN;
		END;

	DECLARE	@UnPackedFilesList VARCHAR(MAX) = '';

	SELECT
		@UnPackedFilesList += 'MOVE ''' + [UPF2].[LogicalName] + ''' TO '''
		+ STUFF([UPF2].[PhysicalName], 1, 1, [UPF2].[NewDriveLetter]) + ''',
'
	FROM
		[#UnpackedFiles2] [UPF2];

	DECLARE	@LogDriveLetter AS CHAR(1);

	SELECT
		@LogDriveLetter = (
							SELECT TOP 1
								[D].[DriveLetter]
							FROM
								[DatabaseRestore].[Drives] [D]
							WHERE
								[D].[DriveType] = 'LOG'
						  );

	SELECT
		@UnPackedFilesList += 'MOVE ''' + [UPF].[LogicalName] + ''' TO '''
		+ STUFF(REPLACE([UPF].[PhysicalName], 'Log\', 'Logs\'), 1, 1,
				@LogDriveLetter) + ''''
	FROM
		[#UnpackedFiles] [UPF]
	WHERE
		[UPF].[Type] = 'L';

	SELECT
		@vFilesToUnpack = @UnPackedFilesList; 

	DROP TABLE [#UnpackedFiles];
	DROP TABLE [#UnpackedFiles2];

	RETURN;




IF NOT EXISTS(SELECT * FROM sys.objects o INNER JOIN sys.schemas s ON o.schema_id=s.schema_id WHERE o.name = 'CorrectOwner' AND s.name = 'DatabaseRestore' AND type = 'P')
	EXEC( 'CREATE PROCEDURE [DatabaseRestore].[CorrectOwner] AS SELECT dt = GETDATE()' )
GO

USE [_ArtsDBAUtil]
GO
/****** Object:  StoredProcedure [DatabaseRestore].[CorrectOwner]    Script Date: 8/3/2017 10:18:44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [DatabaseRestore].[CorrectOwner]
	  @bDebug BIT = 0
	, @DatabaseName VARCHAR(512)
AS
	IF @DatabaseName IN ('SIF_ASM','ArtsRptWebAdmin','SIF_SynchTransLog')
	BEGIN
		EXECUTE ('ALTER AUTHORIZATION ON database::' + @DatabaseName + ' TO sifsynchadmin;')
		PRINT 'Changed Database owner of ' + @DatabaseName + ' to "sifsynchadmin" at ' + CAST(GETDATE() AS VARCHAR(30))
	END
	ELSE
	BEGIN
		EXECUTE ('ALTER AUTHORIZATION ON database::' + @DatabaseName + ' TO sa;')
		PRINT 'Changed Database owner of ' + @DatabaseName + ' to "sa" at ' + CAST(GETDATE() AS VARCHAR(30))
	END



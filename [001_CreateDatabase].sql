/*
Deployment script for DB
CALL SQLCMD.EXE -S localhost -d master -v DatabaseName="TestDB" -v DefaultFilePrefix="TestDB" -i [001_CreateDatabase].sql

This code was generated by a tool.
Changes to this file may cause incorrect behavior and will be lost if
the code is regenerated.
*/

GO
SET ANSI_NULLS, ANSI_PADDING, ANSI_WARNINGS, ARITHABORT, CONCAT_NULL_YIELDS_NULL, QUOTED_IDENTIFIER ON;

SET NUMERIC_ROUNDABORT OFF;


GO
/*
--:setvar DatabaseName "IEAccountingInUSD"
--:setvar DefaultFilePrefix "IEAccountingInUSD"
--:setvar DefaultDataDisk "C"
--:setvar DefaultDataPath "\Program Files\Microsoft SQL Server\MSSQL15.MSSQL_2019\MSSQL\DATA\"
--:setvar DefaultLogPath "\Program Files\Microsoft SQL Server\MSSQL15.MSSQL_2019\MSSQL\DATA\"
*/

GO
PRINT '$(DefaultDataDisk)'
PRINT '$(DefaultDataPath)'
PRINT '$(DefaultLogPath)'

GO

:on error exit
GO
/*
Detect SQLCMD mode and disable script execution if SQLCMD mode is not supported.
To re-enable the script after enabling SQLCMD mode, execute the following:
SET NOEXEC OFF; 
*/
:setvar __IsSqlCmdEnabled "True"
GO
IF N'$(__IsSqlCmdEnabled)' NOT LIKE N'True'
    BEGIN
        PRINT N'SQLCMD mode must be enabled to successfully execute this script.';
        SET NOEXEC ON;
    END

GO
USE [master]
GO

IF EXISTS(SELECT * FROM sys.databases WHERE name = '$(DatabaseName)')
BEGIN
    PRINT N'Droping database $(DatabaseName)...';
	DROP DATABASE [$(DatabaseName)]
END
GO


USE MASTER
PRINT N'Creating database $(DatabaseName)...';
GO
CREATE DATABASE [$(DatabaseName)] 
 CONTAINMENT = NONE 
 ON  PRIMARY 
( NAME = N'$(DatabaseName)_Data', FILENAME = N'$(DefaultDataDisk):$(DefaultDataPath)$(DefaultFilePrefix)_Data.mdf' , SIZE = 102400KB , MAXSIZE = UNLIMITED, FILEGROWTH = 10240KB ), 
 FILEGROUP [$(DatabaseName)_InMemory] CONTAINS MEMORY_OPTIMIZED_DATA  DEFAULT
( NAME = N'$(DatabaseName)_InMemory', FILENAME = N'$(DefaultDataDisk):$(DefaultDataPath)$(DefaultFilePrefix)_InMemory.mdf' , MAXSIZE = UNLIMITED)
 LOG ON 
( NAME = N'$(DatabaseName)_Log', FILENAME = N'$(DefaultDataDisk):$(DefaultDataPath)$(DefaultFilePrefix)_Log.ldf' , SIZE = 102400KB , MAXSIZE = 2048GB , FILEGROWTH = 10240KB )
 --WITH CATALOG_COLLATION = DATABASE_DEFAULT
 COLLATE Cyrillic_General_CI_AS
GO
GO
PRINT N'Creating [publicdw]...';

GO

GO
PRINT N'Creating [staging]...';

GO
ALTER DATABASE [$(DatabaseName)]
    ADD FILEGROUP [staging];


GO
ALTER DATABASE [$(DatabaseName)]
    ADD FILE (NAME = [staging], FILENAME = N'$(DefaultDataDisk):$(DefaultDataPath)$(DefaultFilePrefix)_staging.mdf') TO FILEGROUP [staging];


PRINT N'Creating [audit]...';

GO
ALTER DATABASE [$(DatabaseName)]
    ADD FILEGROUP [audit];


GO
ALTER DATABASE [$(DatabaseName)]
    ADD FILE (NAME = [audit], FILENAME = N'$(DefaultDataDisk):$(DefaultDataPath)$(DefaultFilePrefix)_audit.mdf') TO FILEGROUP [audit];

PRINT N'Creating [upload]...';

GO
ALTER DATABASE [$(DatabaseName)]
    ADD FILEGROUP [upload];


GO
ALTER DATABASE [$(DatabaseName)]
    ADD FILE (NAME = [upload], FILENAME = N'$(DefaultDataDisk):$(DefaultDataPath)$(DefaultFilePrefix)_upload.mdf') TO FILEGROUP [upload];

USE [$(DatabaseName)] 
PRINT N'Creating all schemas...';
GO

GO
IF NOT EXISTS ( SELECT * FROM sys.schemas WHERE name = N'staging' )
    EXEC('CREATE SCHEMA [staging]');

GO
IF NOT EXISTS ( SELECT * FROM sys.schemas WHERE name = N'meta' )
    EXEC('CREATE SCHEMA [meta]');
GO
IF NOT EXISTS ( SELECT * FROM sys.schemas WHERE name = N'uts' )
    EXEC('CREATE SCHEMA [uts]');
GO

IF NOT EXISTS ( SELECT * FROM sys.schemas WHERE name = N'audit' )
    EXEC('CREATE SCHEMA [audit]');
GO

IF NOT EXISTS ( SELECT * FROM sys.schemas WHERE name = N'upload' )
    EXEC('CREATE SCHEMA [upload]');
GO

sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO
sp_configure 'Ole Automation Procedures', 1;
GO
RECONFIGURE;

GO
EXEC master . dbo. sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0' , N'AllowInProcess' , 1
GO
EXEC master . dbo. sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0' , N'DynamicParameters' , 1
GO

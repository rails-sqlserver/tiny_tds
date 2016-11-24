-- Teardown
USE [master];
IF EXISTS (SELECT * FROM sys.databases WHERE [name] = 'tinytdstest')
DROP DATABASE [tinytdstest];
IF EXISTS (SELECT * FROM master.dbo.syslogins WHERE [name] = 'tinytds')
DROP LOGIN [tinytds];
-- Setup
CREATE DATABASE [tinytdstest];
CREATE LOGIN [tinytds] WITH PASSWORD = '', CHECK_POLICY = OFF, DEFAULT_DATABASE = [tinytdstest];
USE [tinytdstest];
CREATE USER [tinytds] FOR LOGIN [tinytds];
EXEC sp_addrolemember N'db_owner', N'tinytds';

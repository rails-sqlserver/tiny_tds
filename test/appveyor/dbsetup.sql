CREATE DATABASE [tinytdstest];
GO
CREATE LOGIN [tinytds] WITH PASSWORD = '', CHECK_POLICY = OFF, DEFAULT_DATABASE = [tinytdstest];
GO
USE [tinytdstest];
CREATE USER [tinytds] FOR LOGIN [tinytds];
GO
EXEC sp_addrolemember N'db_owner', N'tinytds';
GO

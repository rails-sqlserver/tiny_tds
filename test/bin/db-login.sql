CREATE LOGIN [tinytds] WITH PASSWORD = '', CHECK_POLICY = OFF, DEFAULT_DATABASE = [tinytdstest];
USE [tinytdstest];
CREATE USER [tinytds] FOR LOGIN [tinytds];
EXEC sp_addrolemember N'db_owner', N'tinytds';

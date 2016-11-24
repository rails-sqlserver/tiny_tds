USE [master];
IF EXISTS (SELECT * FROM sys.databases WHERE [name] = 'tinytdstest')
DROP DATABASE [tinytdstest];
IF EXISTS (SELECT * FROM master.dbo.syslogins WHERE [name] = 'tinytds')
DROP LOGIN [tinytds];

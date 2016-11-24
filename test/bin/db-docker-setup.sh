#!/usr/bin/env bash

docker pull microsoft/mssql-server-linux
docker run -e 'ACCEPT_EULA=Y' -e 'SA_PASSWORD=super01S3cUr3' -p 1433:1433 -d microsoft/mssql-server-linux

container=$(docker ps -a -q --filter ancestor=microsoft/mssql-server-linux)

docker exec $container apt-get update
docker exec $container apt-get install sqsh -y
docker exec $container sqsh -U sa -P super01S3cUr3 -S localhost -C "
  USE [master];
  IF EXISTS (SELECT * FROM sys.databases WHERE [name] = 'tinytdstest')
  DROP DATABASE [tinytdstest];
  IF EXISTS (SELECT * FROM master.dbo.syslogins WHERE [name] = 'tinytds')
  DROP LOGIN [tinytds];
"
docker exec $container sqsh -U sa -P super01S3cUr3 -S localhost -C "
  CREATE DATABASE [tinytdstest];
"
docker exec $container sqsh -U sa -P super01S3cUr3 -S localhost -C "
  CREATE LOGIN [tinytds] WITH PASSWORD = '', CHECK_POLICY = OFF, DEFAULT_DATABASE = [tinytdstest];
  USE [tinytdstest];
  CREATE USER [tinytds] FOR LOGIN [tinytds];
  EXEC sp_addrolemember N'db_owner', N'tinytds';
"

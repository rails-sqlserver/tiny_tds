$ProgressPreference = 'SilentlyContinue'

if (-not(Test-path "C:\Downloads"))
{
    mkdir "C:\Downloads"
}

$sqlInstallationFile = "C:\Downloads\sqlexpress.exe"
if (-not(Test-path $sqlInstallationFile -PathType leaf))
{
    Write-Host "Downloading SQL Express ..."
    Invoke-WebRequest -Uri "https://go.microsoft.com/fwlink/?linkid=829176" -OutFile "C:\Downloads\sqlexpress.exe"
}

Write-Host "Installing SQL Express ..."
Start-Process -Wait -FilePath "C:\Downloads\sqlexpress.exe" -ArgumentList /qs, /x:"C:\Downloads\setup"
C:\Downloads\setup\setup.exe /q /ACTION=Install /INSTANCENAME=SQLEXPRESS /FEATURES=SQLEngine /UPDATEENABLED=0 /SQLSVCACCOUNT='NT AUTHORITY\System' /SQLSYSADMINACCOUNTS='BUILTIN\ADMINISTRATORS' /TCPENABLED=1 /NPENABLED=0 /IACCEPTSQLSERVERLICENSETERMS

Write-Host "Configuring SQL Express ..."
stop-service MSSQL`$SQLEXPRESS
set-itemproperty -path 'HKLM:\software\microsoft\microsoft sql server\mssql14.SQLEXPRESS\mssqlserver\supersocketnetlib\tcp\ipall' -name tcpdynamicports -value ''
set-itemproperty -path 'HKLM:\software\microsoft\microsoft sql server\mssql14.SQLEXPRESS\mssqlserver\supersocketnetlib\tcp\ipall' -name tcpport -value 1433
set-itemproperty -path 'HKLM:\software\microsoft\microsoft sql server\mssql14.SQLEXPRESS\mssqlserver\' -name LoginMode -value 2

Write-Host "Starting SQL Express ..."
start-service MSSQL`$SQLEXPRESS

Write-Host "Configuring MSSQL for TinyTDS ..."
& sqlcmd -Q "CREATE DATABASE [tinytdstest];"
& sqlcmd -Q "CREATE LOGIN [tinytds] WITH PASSWORD = '', CHECK_POLICY = OFF, DEFAULT_DATABASE = [tinytdstest];"
& sqlcmd -Q "USE [tinytdstest]; CREATE USER [tinytds] FOR LOGIN [tinytds]; EXEC sp_addrolemember N'db_owner', N'tinytds';"

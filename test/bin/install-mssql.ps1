param ([int] $Version)

$ProgressPreference = 'SilentlyContinue'

$DownloadLinkTable = @{
    2017 = "https://go.microsoft.com/fwlink/?linkid=829176";
    2019 = "https://download.microsoft.com/download/7/c/1/7c14e92e-bdcb-4f89-b7cf-93543e7112d1/SQLEXPR_x64_ENU.exe";
    2022 = "https://download.microsoft.com/download/3/8/d/38de7036-2433-4207-8eae-06e247e17b25/SQLEXPR_x64_ENU.exe";
}

$MajorVersionTable = @{
    2017 = 14;
    2019 = 15;
    2022 = 16;
}

if (-not(Test-path "C:\Downloads")) {
    mkdir "C:\Downloads"
}

$sqlInstallationFile = "C:\Downloads\sqlexpress.exe"
if (-not(Test-path $sqlInstallationFile -PathType leaf)) {
    Write-Host "Downloading SQL Express ..."
    Invoke-WebRequest -Uri $DownloadLinkTable[$Version] -OutFile "C:\Downloads\sqlexpress.exe"
}

Write-Host "Installing SQL Express ..."
Start-Process -Wait -FilePath "C:\Downloads\sqlexpress.exe" -ArgumentList /qs, /x:"C:\Downloads\setup"
C:\Downloads\setup\setup.exe /q /ACTION=Install /INSTANCENAME=SQLEXPRESS /FEATURES=SQLEngine /UPDATEENABLED=0 /SQLSVCACCOUNT='NT AUTHORITY\System' /SQLSYSADMINACCOUNTS='BUILTIN\ADMINISTRATORS' /TCPENABLED=1 /NPENABLED=0 /IACCEPTSQLSERVERLICENSETERMS

Write-Host "Configuring SQL Express ..."
stop-service MSSQL`$SQLEXPRESS
set-itemproperty -path "HKLM:\software\microsoft\microsoft sql server\mssql$($MajorVersionTable[$Version]).SQLEXPRESS\mssqlserver\supersocketnetlib\tcp\ipall" -name tcpdynamicports -value ''
set-itemproperty -path "HKLM:\software\microsoft\microsoft sql server\mssql$($MajorVersionTable[$Version]).SQLEXPRESS\mssqlserver\supersocketnetlib\tcp\ipall" -name tcpport -value 1433
set-itemproperty -path "HKLM:\software\microsoft\microsoft sql server\mssql$($MajorVersionTable[$Version]).SQLEXPRESS\mssqlserver\" -name LoginMode -value 2

Write-Host "Starting SQL Express ..."
start-service MSSQL`$SQLEXPRESS

Write-Host "Configuring MSSQL for TinyTDS ..."
& sqlcmd -i './test/sql/db-create.sql'
& sqlcmd -i './test/sql/db-login.sql'

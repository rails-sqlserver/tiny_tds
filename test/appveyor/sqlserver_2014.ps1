[reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null
[reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.SqlWmiManagement") | Out-Null
$serverName = $env:COMPUTERNAME
$instanceName = 'SQL2014'
$smo = 'Microsoft.SqlServer.Management.Smo.'
$wmi = new-object ($smo + 'Wmi.ManagedComputer')

# For the named instance, on the current computer, for the TCP protocol,
# loop through all the IPs and configure them to use the standard port
# of 1433.
# $uri = "ManagedComputer[@Name='$serverName']/ ServerInstance[@Name='$instanceName']/ServerProtocol[@Name='Tcp']"
# $Tcp = $wmi.GetSmoObject($uri)
# foreach ($ipAddress in $Tcp.IPAddresses) {
#   $ipAddress.IPAddressProperties["TcpDynamicPorts"].Value = ""
#   $ipAddress.IPAddressProperties["TcpPort"].Value = "1433"
# }
# $Tcp.Alter()

# Enable TCP/IP
$uri = "ManagedComputer[@Name='$serverName']/ServerInstance[@Name='$instanceName']/ServerProtocol[@Name='Tcp']"
$Tcp = $wmi.GetSmoObject($uri)
$Tcp.IsEnabled = $true
$TCP.alter()
# Start services
Set-Service SQLBrowser -StartupType Manual
Start-Service SQLBrowser
Start-Service "MSSQL`$$instanceName"

<##########################################################################################################

	.SYNOPSIS
		Remotely connect to server via RDP once we confirm we can reach it. 

	.DESCRIPTION
		Remotely connect to server via RDP once we confirm we can reach it. Helpful if waiting on server to 
		complete update or restart and connects as soon as it is reachable. Will continue to retry until
		successful.

	.PARAMETER address
        IP address/FQDN.

	.EXAMPLE
		Connect-RDPServer -address "1.23.34.234"

	.LINK
		https://github.com/rjmccallumbigl/Connect-RDPServer

	.AUTHOR
		Ryan McCallum (rymccall)

	.VERSION
		v0.1: Initial commit

##########################################################################################################>

function Connect-RDPServer {
	param (
		[Parameter(Mandatory = $true, HelpMessage = "Address of the server.")]		
		[string]
		$address
	)	


	# Remotely connect to VM iff TNC results are valid
	Write-Output "Connecting to: $($address)..."
	$testingConnection = $true
	while ($testingConnection) {
		$pingResults = Test-NetConnection -ComputerName $address -Port 3389 -InformationLevel Quiet
		if ($pingResults) {
			$testingConnection = $false
			mstsc "/v:$($address)"
		}
	}
}

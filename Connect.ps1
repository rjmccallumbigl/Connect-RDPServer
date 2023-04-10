<##########################################################################################################

	.SYNOPSIS
		Remotely connect to server via RDP/SSH once we confirm we can reach it.

	.DESCRIPTION
		Remotely connect to server via RDP/SSH once we confirm we can reach it. Helpful if waiting on server to
		complete update or restart and connects as soon as it is reachable. Will continue to retry until
		successful.

	.PARAMETER address
	        IP address/FQDN.

	.PARAMETER userName
	        Username (if using SSH).

	.EXAMPLE
		Connect-RDPServer -address "1.23.34.234"
		RDP 1.23.34.234
		SSH 1.23.34.234 -username "rymccall"

	.LINK
		https://github.com/rjmccallumbigl/Connect-RDPServer

	.AUTHOR
		Ryan McCallum (rymccall)

	.VERSION
		v0.3: Add SSH support
		v0.2: Add alias
		v0.1: Initial commit

##########################################################################################################>

function Connect-RDPServer {
	[alias("RDP")]
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

function Connect-SSHServer {
	[alias("SSH")]
	param (
		[Parameter(Mandatory = $true, HelpMessage = "Address of the server.")]
		[string]
		$address,
		[Parameter(Mandatory = $false, HelpMessage = "username")]
		[string]
		$userName
	)


	# Remotely connect to VM iff TNC results are valid
	Write-Output "Connecting to: $($address)..."
	$testingConnection = $true
	while ($testingConnection) {
		$pingResults = Test-NetConnection -ComputerName $address -Port 22 -InformationLevel Quiet
		if ($pingResults) {
			$testingConnection = $false

			# if no username is passed, prompt for it
			if (!$userName) {
				$userName = Read-Host "Enter user name"
			}
			# Attempt with Linux profiles in Windows Terminal first if installed
			try {
				$wtSettingsLocation = (Get-Item "$Env:LocalAppData\Packages\Microsoft.WindowsTerminal_*\LocalState\settings.json" -ErrorAction Stop)
				$wtSettingsRaw = Get-Content $wtSettingsLocation -Raw
				$wtSettings = $wtSettingsRaw | ConvertFrom-Json
				$wtProfiles = $wtSettings.profiles.list

				# Some WSL options that may be installed in your WSL (modify as necessary)
				$wtLinuxOptions = @("ubuntu", "suse", "debian")
				ForEach ( $wtProfile in $wtProfiles) {
					ForEach ( $wtLinuxOption in $wtLinuxOptions) {
						if ($wtProfile.name -like "*$($wtLinuxOption)*" ) {
							wt -p $wtProfile.name ssh "$($userName)@$($address)"
							return
						}
					}
				}
			}
			catch {
				try {
					# If Windows Terminal is not installed, attempt to SSH via Putty instead
					putty -ssh "$($userName)@$($address)"
					return
				}
				catch {
					# If Windows Terminal and Putty are not installed, attempt to SSH via PowerShell instead. Can be glitchy
					cmd /c "ssh $($userName)@$($address)"
				}
			}
		}
	}
}

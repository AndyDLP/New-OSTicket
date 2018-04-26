function New-OSTicket {
<#
	.SYNOPSIS
		Creates a new ticket on the specified OSTicket instance

	.DESCRIPTION
		Creates a new ticket on the specified OSTicket instance

	.PARAMETER Subject
		The ticket subject

	.PARAMETER Message
		The ticket message / body

	.PARAMETER Name
		The users full name

	.PARAMETER Email
		Email address of the user

	.PARAMETER PhoneNumber
		Phone number of the submitter. If the extension is included, use a capital 'X' followed by the extension

	.PARAMETER IpAddress
		The sending IpAddress (can be spoofed?)

	.PARAMETER topicID
		The help topic ID to be associated with the ticket

	.PARAMETER MessageType
		The format type of the message, either text/html or text/plain

	.PARAMETER Alert
		Send an alert to agents on ticket creation

	.PARAMETER APIKey
		The API key to send to the OSTicket install

	.PARAMETER AutoRespond
		Automatically respond with the ticket info to the email defined in ticket creation

	.PARAMETER Server
		The server to send the API call to. Can be FQDN or IP

	.PARAMETER Priority
		The priority ID for the new ticket to assume

	.PARAMETER CustomFields
		A list of custom (not present in base install) fields and their desired values

	.PARAMETER TicketSource
		The ticket source type, such as email, phone or API

	.PARAMETER Attachments
		An array of file paths to attach to the initial message

	.EXAMPLE
		PS C:\> New-OSTicket -Subject 'Please Fix Microwave' -Message 'Someone put fish in it and no one wants to go near it' -Name 'Random User' -Email 'test@example.com'

	.NOTES
		Updated: 2018-04-21
#>

	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true,
				   HelpMessage = 'The ticket subject')]
		[ValidateNotNullOrEmpty()]
		[string]$Subject,
		[Parameter(Mandatory = $true,
				   HelpMessage = 'The ticket message / body')]
		[ValidateNotNullOrEmpty()]
		[string]$Message,
		[Parameter(Mandatory = $true,
				   HelpMessage = 'The users full name')]
		[ValidateNotNullOrEmpty()]
		[string]$Name,
		[Parameter(Mandatory = $true,
				   HelpMessage = 'Email address of the user')]
		[ValidatePattern('\w+([-+.]\w+)*@\w+([-.]\w+)*\.\w+([-.]\w+)*')]
		[string]$Email,
		[Parameter(HelpMessage = 'Phone number of the submitter. If the extension is included, use a capital X followed by the extension')]
		[string]$PhoneNumber = "",
		[Parameter(HelpMessage = 'The source IP address (can be spoofed)')]
		[ValidatePattern('\A(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}')]
		[string]$IpAddress = "",
		[Parameter(HelpMessage = 'The help topic ID to be associated with the ticket')]
		[string]$TopicId,
		[ValidateSet('text/plain', 'text/html', IgnoreCase = $true)]
		[string]$MessageType = "text/plain",
		[Parameter(HelpMessage = 'Send an alert to agents on ticket creation')]
		[boolean]$Alert = $true,
		[Parameter(Mandatory = $true,
				   HelpMessage = 'The API key to send to the OSTicket install')]
		[ValidateNotNullOrEmpty()]
		[string]$ApiKey,
		[Parameter(HelpMessage = 'Automatically respond with the ticket info to the email defined in ticket creation')]
		[boolean]$AutoRespond = $true,
		[Parameter(Mandatory = $true,
				   HelpMessage = 'The server to send the API call to. Can be FQDN or IP')]
		[string]$Server,
		[Parameter(HelpMessage = 'The priority ID for the new ticket to assume')]
		[string]$Priority,
		[Parameter(HelpMessage = 'A list of custom (not present in base install) fields and their desired values')]
		[hashtable]$CustomFields = @{ },
		[Parameter(HelpMessage = 'The ticket source type, such as email, phone or API')]
		[string]$TicketSource = "API",
		[Parameter(Mandatory = $false,
				   HelpMessage = 'An array of file paths to attach to the initial message')]
		[string[]]$Attachments
	)

	begin {
		Add-Type -AssemblyName "System.Web"
	}

	process {
		$AttachableFiles = @()

		foreach ($FilePath in $Attachments) {
			$FileToAttach = Get-Item -Path $FilePath
			if ($FileToAttach.Length -lt 2MB) {
				Write-Verbose "Attaching file: $($FileToAttach.Name)"
				$MimeType = [System.Web.MimeMapping]::GetMimeMapping($FilePath.FullName)
				$Base64FileData = [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes($FilePath))
				$AttachableFiles = $AttachableFiles + @(@{ ($FileToAttach.Name) = "data:$MimeType;base64,$Base64FileData" })
			} else {
				Write-Warning "Skipping file: $($FileToAttach.Name), as it is over the 2MB limit"
			}
		}

		$Params = $CustomFields + @{
			# Required
			name = $Name;
			email = $Email;
			subject = $Subject;
			message = $Message;

			# optional
			phone = $PhoneNumber;
			ip = $IpAddress;
			topicID = $topicID;
			alert = $Alert;
			autorespond = $AutoRespond;
			messagetype = $MessageType;
			source = $TicketSource;
			priority = $Priority;
			attachments = $AttachableFiles
		} | ConvertTo-Json

		# Add the correct JSON endpoint
		$URI = "http://$Server/api/tickets.json"
		$HTTPResponse = Invoke-WebRequest -Uri $URI -Headers @{ "X-API-Key" = $APIKey } -Body $Params -UseDefaultCredentials -Method Post -ContentType "application/json" -ErrorAction Stop

		# If it fails for whatever reason, let us know
		if ($HTTPResponse.StatusCode -ne 201) {
			Write-Warning "Unexpected HTTP status code: $($HTTPResponse.StatusCode)"
			Write-Warning "$($HTTPResponse.RawContent)"
		}
	}

	end {

	}
}

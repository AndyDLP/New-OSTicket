function New-OSTicket {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $True, HelpMessage = "The ticket title / subject")]
        [string]$Title,

        [Parameter(Mandatory = $True, HelpMessage = "The ticket message / body")]
        [string]$Message,

        [Parameter(HelpMessage = "User forename")]
        [string]$Forename = "",

        [Parameter(HelpMessage = "User surname")]
        [string]$Surname = "",

        [Parameter(HelpMessage = "Email address of the user")]
        [string]$Email = "",

        [Parameter(HelpMessage = "The contact phone number of the user")]
        [string]$PhoneNumber = "",

        [Parameter(HelpMessage = "The department to create the ticket in, must match exactly")]
        [string]$Department = "",

        [Parameter(HelpMessage = "The computer that the ticket was generated from, can be spoofed")]
        [string]$ComputerName = "$env:COMPUTERNAME",

        [Parameter(HelpMessage = "The sending IP (can be spoofed?)")]
        [string]$ip = "",

        [Parameter(HelpMessage = "The ticket cateogry, must match exactly")]
        [string]$Category = "",

        [Parameter(HelpMessage = "Topic ID number from ticket")]
        [string]$topicID = "1",

        [Parameter(HelpMessage = "Room")]
        [string]$room = "",

        [Parameter(HelpMessage = "The API key to send to the OSTicket install")]
        [string]$APIKey = "",

        [Parameter(HelpMessage = 'The application URI to send the POST request to e.g. [url]/api/tickets.json)']
        [string]$URI = ""
    )

    $Params = @{
        name = "$Forename $Surname";
        email = $Email;
        phone = $PhoneNumber;
        Department = $Department;
        subject = $Title;
        ip = $ip;
        message = $Message;
        topicID = $topicID;

        # Custom fields
        FirstName = $Forename; # Custom
        LastName = $Surname; # Custom
        Category = $Category; # Custom
        ComputerName = $ComputerName; # Custom
        room = $room; # Custom
        Title = $Title; # Custom
        Body = $Message; # Custom
        # Todo: fix this
        #attachments = @{"Filename.txt" = ()}
    } | ConvertTo-Json


    # works!
    Invoke-WebRequest -Uri $URI -Headers @{'X-API-Key'=$APIKey} -Body $Params -UseDefaultCredentials -Method Post -ContentType "application/json"
}

New-OSTicket -Title "Test Title" -Message "Test Message"
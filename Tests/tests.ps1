if(Get-Module PSGELF) {
    Remove-Module PSGELF
}

Import-Module PSGELF -ErrorAction Stop

#These Pester tests are not the prettiest. But, they get the job done. They are a combintation of function and intergration tests.
#This script WILL send data to your graylog server.

$PesterHostname = "pestertest"
$GraylogUriPrefix = "http://"
$GraylogServer = "graylog"
$GraylogApiPort = 12900
$GraylogUDPPort = 12201
$GraylogTCPPort = 12202
$GraylogUri = $GraylogUriPrefix + $GraylogServer + ":" + $GraylogApiPort

$GraylogCred = Get-Credential -Message "Please enter a username and password for the graylog to run the tests."

Describe "New-PSGelfObject" {

        
        $TestTime = Get-Date -Date "2016-01-01 08:00:00"
        $TestTimeUnix = Get-Date($TestTime).ToUniversalTime() -uformat "%s"

        $ExpectedObject = New-Object -TypeName PSObject    
        $ExpectedObject | Add-Member -MemberType NoteProperty -Name version -Value "1.1"
        $ExpectedObject | Add-Member -MemberType NoteProperty -Name ShortMessage -Value "This is a short Message"
        $ExpectedObject | Add-Member -MemberType NoteProperty -Name host -Value "testserver"
        $ExpectedObject | Add-Member -MemberType NoteProperty -Name full_message -Value "This is a full Message"
        $ExpectedObject | Add-Member -MemberType NoteProperty -Name timestamp  -Value $TestTimeUnix
        $ExpectedObject | Add-Member -MemberType NoteProperty -Name level  -Value 8
        $ExpectedObject | Add-Member -MemberType NoteProperty -Name facility -Value "Facility" 
        $ExpectedObject | Add-Member -MemberType NoteProperty -Name line -Value 202 
        $ExpectedObject | Add-Member -MemberType NoteProperty -Name file -Value "C:\log.txt" 
        $ExpectedObject | Add-Member -MemberType NoteProperty -Name _test -Value "test"
        $ExpectedObject | Add-Member -MemberType NoteProperty -Name _test2 -Value "test2"


        $PSGelfObject = New-PSGelfObject -GelfServer "graylog" `
        -Port 12201 `
        -HostName $ExpectedObject.host `
        -ShortMessage $ExpectedObject.ShortMessage `
        -FullMessage $ExpectedObject.full_message `
        -DateTime $TestTime `
        -Level $ExpectedObject.level `
        -Facility $ExpectedObject.facility `
        -Line $ExpectedObject.Line `
        -File $ExpectedObject.File `
        -AdditionalField @{test = $ExpectedObject._test; test2 = $ExpectedObject._test2}

    It "Validates the returned object" {
        [String]::Compare(($PSGelfObject | ConvertTo-Json),($ExpectedObject | ConvertTo-Json),$true) | Should Be 0
    }

    It "Should throw an ID present error" {
        {New-PSGelfObject -Port 1337 -GelfServer $PesterHostname  -ShortMessage "Testing throw" -AdditionalField @{id = "id test";}} | Should Throw 
    }

    It "Should not throw an ID present error" {
        {New-PSGelfObject -Port 1337 -GelfServer $PesterHostname  -ShortMessage "Testing throw" -AdditionalField @{blah = "blah test";}} | Should Not Throw 
    }
}
        

Describe "Compress-PSGelfString" {
    It "Validates the return type is Byte" {
        Compress-PSGelfString -ToZip $(Get-Process) | Should BeOfType Byte
    }
}

Describe "Send-PSGelfUDP" {
    It "Sends a message that doesn't need chunking to Graylog via UDP and queries Graylog to make sure the message made it" {

        $TestGuid = New-Guid
        Send-PSGelfUDP -GelfServer $GraylogServer -Port $GraylogUDPPort -HostName $PesterHostname  -ShortMessage "Message from Pester Test" -AdditionalField @{UniqueID = $TestGuid} 
        
        $RestURI = $GraylogUri + "/search/universal/relative?query=source%3A$PesterHostname%20AND%20UniqueID%3A$TestGuid&range=300&fields=message%2CUniqueID"

        Start-Sleep 5
        
        $RestCsv = Invoke-WebRequest  -Uri $RestURI -Credential $GraylogCred -Method Get
        $GraylogMessage = $RestCsv | ConvertFrom-Csv

        $GraylogMessage.UniqueID | Should MatchExactly $TestGuid
    }

    It "Sends a message that does need chunking to Graylog via UDP and queries Graylog to make sure the message has the correct value." {

        $TestGuid = New-Guid

        $ShortMessage = ""
        1..9999 | ForEach-Object {
            $ShortMessage += $_ 
            $ShortMessage += "`n"
        }
        Send-PSGelfUDP -GelfServer $GraylogServer `
            -Port $GraylogUDPPort `
            -HostName $PesterHostname `
            -ShortMessage $ShortMessage `
            -AdditionalField @{UniqueID = $TestGuid} 
        
        $RestURI = $GraylogUri + "/search/universal/relative?query=source%3A$PesterHostname%20AND%20UniqueID%3A$TestGuid&range=300&fields=message%2CUniqueID"

        Start-Sleep 5
        
        $RestCsv = Invoke-WebRequest  -Uri $RestURI -Credential $GraylogCred -Method Get
        $GraylogMessage = $RestCsv | ConvertFrom-Csv

        $($GraylogMessage.message -split "\\n")[-2] | Should be 9999

    }

    It "Sends a message to Graylog via UDP and queries Graylog to make sure all the fields match." {

        $TestGuid = New-Guid

        $ShortMessage = "Short Message" 
        $FullMessage = "Full Message" 
        $DateTime = $(Get-Date) 
        $Level = 5 
        $Facility = "logs" 
        $Line = 212 
        $File = "C:\logs"

        Send-PSGelfUDP -GelfServer $GraylogServer `
            -Port $GraylogUDPPort `
            -ShortMessage $ShortMessage `
            -FullMessage $FullMessage `
            -HostName $PesterHostname `
            -DateTime $DateTime `
            -Level $Level `
            -Facility $Facility `
            -Line $Line `
            -File $File `
            -AdditionalField @{UniqueID = $TestGuid}
        
        $RestURI = $GraylogUri + "/search/universal/relative?query=source%3A$PesterHostname%20AND%20UniqueID%3A$TestGuid&range=300&fields=message%2CUniqueID%2Cfacility%2Cfile%2Cfull_message%2Clevel%2Cline%2Csource"

        Start-Sleep 3
        
        $RestCsv = Invoke-WebRequest  -Uri $RestURI -Credential $GraylogCred -Method Get
        $GraylogMessage = $RestCsv | ConvertFrom-Csv

        $GraylogMessage.message | Should be $ShortMessage
        $GraylogMessage.full_message | Should be $FullMessage
        $GraylogMessage.source | Should be $PesterHostname
        $GraylogMessage.message | Should be $ShortMessage
        #$GraylogMessage.timestamp | Should be $ShortMessage
        $GraylogMessage.Level | Should be $Level
        $GraylogMessage.facility | Should be $Facility
        $GraylogMessage.Line | Should be $Line
        $GraylogMessage.File | Should be $File

    }

}
Describe "Send-PSGelfUDPFromObject" {
    It "Sends modified Event Logs from your computer to Graylog via UDP and queries Graylog to make sure the message made it" {

        $TestGuid = New-Guid

        $NumEvents = 10
        
        $WinEvents = Get-WinEvent Application -MaxEvents $NumEvents 
        $WinEvents | Add-Member -MemberType NoteProperty -Name UniqueID -Value $TestGuid.Guid
        #We removed MachineName and went ahead and set the host
        $WinEvents = $WinEvents | Select * -ExcludeProperty MachineName,TimeCreated
        $WinEvents = $WinEvents | Select @{Name="MachineName";Expression={$PesterHostname}},*
        $WinEvents = $WinEvents | Select @{Name="TimeCreated";Expression={Get-Date}},*
        $WinEvents | Send-PSGelfUDPFromObject -GelfServer $GraylogServer -Port $GraylogUDPPort

        
        $RestURI = $GraylogUri + "/search/universal/relative?query=source%3A$PesterHostname%20AND%20UniqueID%3A$TestGuid&range=300&fields=message%2CUniqueID"

        Start-Sleep 3
        
        $RestCsv = Invoke-WebRequest  -Uri $RestURI -Credential $GraylogCred -Method Get
        $GraylogMessage = $RestCsv | ConvertFrom-Csv

        $GraylogMessage.Count | Should MatchExactly $NumEvents

    }
}

Describe "Send-PSGelfTCPFromObject" {
    It "Sends modified Event Logs from your computer to Graylog via UDP and queries Graylog to make sure the message made it" {

        $TestGuid = New-Guid

        $NumEvents = 10
        
        $WinEvents = Get-WinEvent Application -MaxEvents $NumEvents 
        $WinEvents | Add-Member -MemberType NoteProperty -Name UniqueID -Value $TestGuid.Guid
        #We removed MachineName and went ahead and set the host
        $WinEvents = $WinEvents | Select * -ExcludeProperty MachineName,TimeCreated
        $WinEvents = $WinEvents | Select @{Name="MachineName";Expression={$PesterHostname}},*
        $WinEvents = $WinEvents | Select @{Name="TimeCreated";Expression={Get-Date}},*
        $WinEvents | Send-PSGelfTCPFromObject -GelfServer $GraylogServer -Port $GraylogTCPPort

        
        $RestURI = $GraylogUri + "/search/universal/relative?query=source%3A$PesterHostname%20AND%20UniqueID%3A$TestGuid&range=300&fields=message%2CUniqueID"

        Start-Sleep 3
        
        $RestCsv = Invoke-WebRequest  -Uri $RestURI -Credential $GraylogCred -Method Get
        $GraylogMessage = $RestCsv | ConvertFrom-Csv

        $GraylogMessage.Count | Should MatchExactly $NumEvents

    }
}


Describe "Send-PSGelfTCP" {
    It "Sends a small message to Graylog via TCP and queries Graylog to make sure the message made it" {

        $TestGuid = New-Guid
        Send-PSGelfTCP -GelfServer $GraylogServer -Port $GraylogTCPPort -HostName $PesterHostname  -ShortMessage "Message from Pester Test" -AdditionalField @{UniqueID = $TestGuid} 
        
        $RestURI = $GraylogUri + "/search/universal/relative?query=source%3A$PesterHostname%20AND%20UniqueID%3A$TestGuid&range=300&fields=message%2CUniqueID"

        Start-Sleep 5
        
        $RestCsv = Invoke-WebRequest  -Uri $RestURI -Credential $GraylogCred -Method Get
        $GraylogMessage = $RestCsv | ConvertFrom-Csv

        $GraylogMessage.UniqueID | Should MatchExactly $TestGuid
    }

    It "Sends a large message to Graylog via TCP and queries Graylog to make sure the message has the correct value." {

        $TestGuid = New-Guid

        $ShortMessage = ""
        1..9999 | ForEach-Object {
            $ShortMessage += $_ 
            $ShortMessage += "`n"
        }
        Send-PSGelfTCP -GelfServer $GraylogServer `
            -Port $GraylogTCPPort `
            -HostName $PesterHostname `
            -ShortMessage $ShortMessage `
            -AdditionalField @{UniqueID = $TestGuid} 
        
        $RestURI = $GraylogUri + "/search/universal/relative?query=source%3A$PesterHostname%20AND%20UniqueID%3A$TestGuid&range=300&fields=message%2CUniqueID"

        Start-Sleep 5
        
        $RestCsv = Invoke-WebRequest  -Uri $RestURI -Credential $GraylogCred -Method Get
        $GraylogMessage = $RestCsv | ConvertFrom-Csv

        $($GraylogMessage.message -split "\\n")[-2] | Should be 9999

    }

    It "Sends a message to Graylog via TCP and queries Graylog to make sure all the fields match." {

        $TestGuid = New-Guid

        $ShortMessage = "Short Message" 
        $FullMessage = "Full Message" 
        $DateTime = $(Get-Date) 
        $Level = 5 
        $Facility = "logs" 
        $Line = 212 
        $File = "C:\logs"

        Send-PSGelfTCP -GelfServer $GraylogServer `
            -Port $GraylogTCPPort `
            -ShortMessage $ShortMessage `
            -FullMessage $FullMessage `
            -HostName $PesterHostname `
            -DateTime $DateTime `
            -Level $Level `
            -Facility $Facility `
            -Line $Line `
            -File $File `
            -AdditionalField @{UniqueID = $TestGuid}
        
        $RestURI = $GraylogUri + "/search/universal/relative?query=source%3A$PesterHostname%20AND%20UniqueID%3A$TestGuid&range=300&fields=message%2CUniqueID%2Cfacility%2Cfile%2Cfull_message%2Clevel%2Cline%2Csource"

        Start-Sleep 3
        
        $RestCsv = Invoke-WebRequest  -Uri $RestURI -Credential $GraylogCred -Method Get
        $GraylogMessage = $RestCsv | ConvertFrom-Csv

        $GraylogMessage.message | Should be $ShortMessage
        $GraylogMessage.full_message | Should be $FullMessage
        $GraylogMessage.source | Should be $PesterHostname
        $GraylogMessage.message | Should be $ShortMessage
        #$GraylogMessage.timestamp | Should be $ShortMessage
        $GraylogMessage.Level | Should be $Level
        $GraylogMessage.facility | Should be $Facility
        $GraylogMessage.Line | Should be $Line
        $GraylogMessage.File | Should be $File

    }

}


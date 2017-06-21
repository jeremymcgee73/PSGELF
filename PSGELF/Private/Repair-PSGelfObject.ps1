function Repair-PSGelfObject
{
    [cmdletbinding()]
    Param
    (
        [Parameter(Mandatory )][PSCustomObject]$GelfMessage
    )

        #Most of these changes are so you can easily pipe Get-WinEvent to this function.

        if($GelfMessage.MachineName) {
            Write-Verbose 'The property MachineName is being added as host.'
            $GelfMessage = $GelfMessage | Select-Object @{Name="host";Expression={$_."MachineName"}},*
        }

        if(!($GelfMessage.host)) {
            Write-Verbose 'There wasnt a host set in the object. The host is set to the local machine.'
            $GelfMessage = $GelfMessage | Select-Object @{Name="host";Expression={& {hostname}}},*
        }

        if($GelfMessage.TimeCreated) {
            Write-Verbose 'There was a property named TimeCreated. We are going to infer that is what the timestamp needs to be.'
            $GelfMessage = $GelfMessage | Select-Object @{Name="timestamp";Expression={Get-Date($_."TimeCreated").ToUniversalTime() -uformat "%s"}},* -ExcludeProperty TimeCreated
        }

        if($GelfMessage.ID) {
            Write-Verbose 'There should not be a property named ID in the object. The property ID is being reanmed to EventID.'
            $GelfMessage = $GelfMessage | Select-Object @{Name="_EventID";Expression={$_."ID"}},* -ExcludeProperty ID
        }

        if($GelfMessage.ShortMessage)
        {
            $GelfMessage = $GelfMessage | Select-Object @{Name="short_message";Expression={$_."ShortMessage"}},* -ExcludeProperty ShortMessage
        }
        else {
            if($GelfMessage.Message) {
                $GelfMessage = $GelfMessage | Select-Object @{Name="short_message";Expression={$_."Message"}},* -ExcludeProperty Message
                Write-Verbose 'ShortMessage is a required property. The property Message has been renamed ShortMessage to meet the requirments.'
            }
            else {
                Write-Error 'There must be a ShortMessage or Message property.  You can use Select-Object to rename an existing property. The message has not been sent.'
                Return
            }
            
        }
        #We have to rename all of the non default fields to start with an underscore.

        $DefaultFields = @("version","host","short_message","full_message","timestamp","level","facility","line","file")
        
        $GelfMessage | Get-Member -MemberType NoteProperty | Where-Object {$DefaultFields -notcontains $_.Name -and $_.Name -notlike "_*"} |  ForEach-Object {
            $FieldToBeRenamed = $_.Name
            $GelfMessage = $GelfMessage | Select-Object @{Name="_$FieldToBeRenamed";Expression={$_."$FieldToBeRenamed"}},* -ExcludeProperty $FieldToBeRenamed
        }

        $GelfMessage
}
<#
.Synopsis
   Sends a GELF message via TCP.
.DESCRIPTION
   This function sends a GELF message via TCP to a server supporting GELF. This function should be used if you don't want to pipe input.
.EXAMPLE
   Send-PSGelfTCP -GelfServer graylog -Port 12202 -ShortMessage "This is a short message"
.EXAMPLE
   Send-PSGelfTCP -GelfServer graylog -Port 12202 -HostName "dc01" -AdditionalField @{TestField1 = "wow!";TestField2 = "wow2"}  -ShortMessage "Test Additional Fields"
#>
function Send-PSGelfTCP
{
    [cmdletbinding()]
    Param
    (
        [Parameter(Mandatory)][String]$GelfServer,

        [Parameter(Mandatory)][Int]$Port,

        [Parameter()][String]$HostName,

        [Parameter(Mandatory)][String]$ShortMessage,

        [Parameter()][String]$FullMessage,

        [Parameter()][System.DateTime]$DateTime,

        [Parameter()][Int]$Level,

        [Parameter()][String]$Facility,

        [Parameter()][Int]$Line,

        [Parameter()][String]$File,

        [Parameter()][Hashtable]$AdditionalField
    )

    Begin
    {
    }
    Process
    {
        $GelfMessage = New-PSGelfObject @PsBoundParameters
        Send-PSGelfTCPFromObject -GelfServer $GelfServer -Port $Port -GelfMessage $GelfMessage
    }
    End
    {
    }
}
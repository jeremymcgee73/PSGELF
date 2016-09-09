<#
.Synopsis
   Sends a GELF message via UDP.
.DESCRIPTION
   This function sends a GELF message via UDP to a server supporting GELF. This function should be used if you don't want to pipe input.
.EXAMPLE
   Send-PSGelfUDP -GelfServer graylog -Port 12201 -ShortMessage "This is a short message"
.EXAMPLE
   Send-PSGelfUDP -GelfServer graylog -Port 12201 -HostName "dc01" -AdditionalField @{TestField1 = "wow!";TestField2 = "wow2"}  -ShortMessage "Test Additional Fields"
#>
function Send-PSGelfUDP
{
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
        Send-PSGelfUDPFromObject -GelfServer $GelfServer -Port $Port -GelfMessage $GelfMessage
    }
    End
    {
    }
}
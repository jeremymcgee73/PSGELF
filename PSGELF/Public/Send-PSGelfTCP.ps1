<#
.Synopsis
   Sends a GELF message via TCP.
.PARAMETER GelfServer
   Hostname or IP address of the GELF server to send messages to.
.PARAMETER Port
   Port number used to communicate with the GELF server.
.PARAMETER Encrypt
   Use to use SSL/TLS encryption with the GELF server.
.PARAMETER HostName
   The name of the host, source or application that sent this message.
.PARAMETER ShortMessage
   A short descriptive message.
.PARAMETER FullMessage
   A long message that can i.e. contain a backtrace.
.PARAMETER DateTime
   Timestamp when the event ocurred. Should be set but will default to the
   current timestamp if absent.
.PARAMETER Level
   The level equal to the standard syslog levels - default is 1 (alert)

   0    Emergency
   1    Alert
   2    Critical
   3    Error
   4    Warning
   5    Notice
   6    Informational
   7    Debug
.PARAMETER Facility
   A facility code used to specify the type of program that is logging the
   message. Deprecated. Send as an additional field instead.
.PARAMETER Line
   The line in a file that caused the error (decimal). Deeprecated. Send as an
   additional field instead.
.PARAMETER File
   The file (with path if you want) that caused the error. Deprecated. Send as
   an additional field instead.
.PARAMETER AdditionalField
   Hashtable of additional fields to send. The key will be the additional field
   name.
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
        [Parameter()][Switch]$Encrypt,
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

    Process
    {
      $GelfParams = @{} + $PsBoundParameters
      $GelfParams.Remove('GelfServer')
      $GelfParams.Remove('Port')
      $GelfParams.Remove('Encrypt')

      $GelfMessage = New-PSGelfObject @GelfParams      
      Send-PSGelfTCPFromObject -GelfServer $GelfServer -Port $Port -Encrypt:$Encrypt.IsPresent -GelfMessage $GelfMessage
    }
}
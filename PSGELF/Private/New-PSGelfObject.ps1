function New-PSGelfObject
{
    [cmdletbinding()]
    Param
    (
        [Parameter(Mandatory)][String]$GelfServer,

        [Parameter(Mandatory)][Int]$Port,

        [Parameter()][switch]$Encrypt,

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
        $Message = New-Object –TypeName PSObject

        $Message | Add-Member –MemberType NoteProperty –Name version –Value "1.1"
        $Message | Add-Member –MemberType NoteProperty –Name ShortMessage –Value $ShortMessage

        if (!$HostName) {
            $HostName = & {hostname}
        }

        $Message | Add-Member –MemberType NoteProperty –Name host –Value $HostName

        if ($FullMessage) {
            $Message | Add-Member –MemberType NoteProperty –Name full_message –Value $FullMessage
        }
        if ($DateTime) {
            $TimeStampConversion = Get-Date($DateTime).ToUniversalTime() -uformat "%s"
            $Message | Add-Member –MemberType NoteProperty –Name timestamp  –Value $TimeStampConversion
        }
        if ($Level ) {
            $Message | Add-Member –MemberType NoteProperty –Name level  –Value $Level
        }
        if ($Facility) {
            $Message | Add-Member –MemberType NoteProperty –Name facility –Value $Facility
        }
        if ($Line) {
            $Message | Add-Member –MemberType NoteProperty –Name line –Value $Line
        }

        if ($File) {
            $Message | Add-Member –MemberType NoteProperty –Name file –Value $File
        }

        if ($AdditionalField) {

            ($AdditionalField).GetEnumerator() | ForEach-Object {
                $FieldName = "_" + $_.Name
                $FieldValue = $_.Value

                if(!($FieldName -eq "_id")) {
                    $Message | Add-Member –MemberType NoteProperty –Name $FieldName –Value $FieldValue
                }
                else {
                    throw 'An additionional field can not be named ID.'
                }
            }
        }

        Write-Output $Message
    }
}
<#
.Synopsis
   Sends an PSObject to Graylog via UDP.
.DESCRIPTION
   This function sends an PSObject to Graylog via UDP to a server supporting GELF. This function should be used if you do want to pipe input.
.EXAMPLE
   Get-WinEvent Setup | Send-PSGelfUDPFromObject -GelfServer graylog -Port 12202
#>
function Send-PSGelfUDPFromObject
{
    [cmdletbinding()]
    Param
    (
        [Parameter(Mandatory)][String]$GelfServer,

        [Parameter(Mandatory)][Int]$Port,

        [Parameter(Mandatory,ValueFromPipeline )][PSCustomObject]$GelfMessage
    )

    Begin
    {
    }
    Process
    {
        if($GelfServer -notmatch "^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$")
        {
            $GelfServer = [String]$([System.Net.Dns]::GetHostAddressesAsync($GelfServer)).Result[0]  
        }

        # Create a UDP client to be used to send data
        $Address = [system.net.IPAddress]::Parse($GelfServer) 
        $EndPoint = New-Object System.Net.IPEndPoint($Address, $Port)
        $UdpClient = new-Object System.Net.Sockets.UdpClient        

        $RepairedGelfMessage = Repair-PSGelfObject -GelfMessage $GelfMessage

        #$CompressedJSON = Compress-PSGelfString($RepairedGelfMessage | ConvertTo-Json -Compress)
        $CompressedJSON = [System.Text.Encoding]::ASCII.GetBytes($($RepairedGelfMessage | ConvertTo-Json -Compress))

        #We only need to chunk if the packet is greater than 8192 bytes. 
        #...I left some wiggle room.

        if($CompressedJSON.Length -ge 8100) {
            $ChunkSize = 6000
            $NumOfChunks = [math]::ceiling($CompressedJSON.Length / $ChunkSize) - 1
            $TotalChunks = [Byte]$($NumOfChunks + 1)

            if($TotalChunks -ge 128) {
                Write-Error 'There are too many chunks to send. The maxium number of chunks is 128.'
                Return                
            }

            #GELF Magic Bytes
            $HeaderBytes = [byte]0x1e,[byte]0x0f

            #Random Message ID for the Message. 8 Bytes
            [Object]$Random = New-Object System.Random
            $GelfMessageID = New-Object Byte[] 8
            $Random.NextBytes($GelfMessageID)

        
            0 .. $NumOfChunks | ForEach-Object {
                #Sequence number of this chunk. Must start at 0
                $SequenceNum = [byte]$_

                #Indexes of where the chunk will start and stop
                $StartPacketIndex = $_ * $ChunkSize
                $EndPacketIndex = $StartPacketIndex + $ChunkSize - 1

                $ChunkData = $CompressedJSON[$StartPacketIndex .. $EndPacketIndex]

                $ChunkPacket = $HeaderBytes + $GelfMessageID + $SequenceNum + $TotalChunks + $ChunkData
                #UDP.Send returns the length of the data sent. We don't need this.

                $UDPClient.SendAsync($ChunkPacket, $ChunkPacket.Length,$EndPoint) | Out-Null
            }

        }
        else {
            $UDPclient.SendAsync($CompressedJSON, $CompressedJSON.Length,$EndPoint) | Out-Null
        }
    }
    End
    {
    }
}
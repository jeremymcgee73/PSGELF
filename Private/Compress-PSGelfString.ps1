function Compress-PSGelfString ([String]$ToZip) {
    #This creates a Byte array of GZiPd data.
    $ms = New-Object System.IO.MemoryStream
    $cs = New-Object System.IO.Compression.GZipStream($ms, [System.IO.Compression.CompressionMode]::Compress)
    $sw = New-Object System.IO.StreamWriter($cs)
    $sw.Write($ToZip)
    $sw.Close();

    Return $ms.ToArray()

}
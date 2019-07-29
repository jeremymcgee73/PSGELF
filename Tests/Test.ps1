$TestTime = Get-Date -Date '2016-01-01 08:00:00'
$TestTimeUnix = [double]$(Get-Date($TestTime).ToUniversalTime() -uformat "%s")

$ExpectedObject = New-Object -TypeName PSObject    
$ExpectedObject | Add-Member -MemberType NoteProperty -Name version -Value '1.1'
$ExpectedObject | Add-Member -MemberType NoteProperty -Name ShortMessage -Value 'This is a short Message'
$ExpectedObject | Add-Member -MemberType NoteProperty -Name full_message -Value 'This is a full Message'
$ExpectedObject | Add-Member -MemberType NoteProperty -Name timestamp -Value $TestTimeUnix
$ExpectedObject | Add-Member -MemberType NoteProperty -Name level  -Value 8
$ExpectedObject | Add-Member -MemberType NoteProperty -Name facility -Value 'Facility' 
$ExpectedObject | Add-Member -MemberType NoteProperty -Name line -Value 202 
$ExpectedObject | Add-Member -MemberType NoteProperty -Name file -Value 'C:\log.txt'
$ExpectedObject | Add-Member -MemberType NoteProperty -Name _test -Value 'test'
$ExpectedObject | Add-Member -MemberType NoteProperty -Name _test2 -Value 'test2'

$PSGelfObject = New-PSGelfObject  `
-ShortMessage $ExpectedObject.ShortMessage `
-FullMessage $ExpectedObject.full_message `
-DateTime $TestTime `
-Level $ExpectedObject.level `
-Facility $ExpectedObject.facility `
-Line $ExpectedObject.Line `
-File $ExpectedObject.File `
-AdditionalField @{test = $ExpectedObject._test; test2 = $ExpectedObject._test2}


[String]::Compare(($PSGelfObject | ConvertTo-Json),($ExpectedObject | ConvertTo-Json),$true) | Should Be 0

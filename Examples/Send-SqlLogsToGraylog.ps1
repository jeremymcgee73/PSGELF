#This is a simplified example on how to poll logs from SQL and send them to Graylog.

$sqlConnection = New-SQLConnection -ServerInstance SQLServer -Database "ApplicationLogs"

$query = "SELECT * ,DATEDIFF(s, '19700101',DATEADD(hour, +6, DateEntered)) AS TimeStamp FROM AppsLog"

Invoke-Sqlcmd2 -Query $query -SQLConnection $sqlConnection -As  | Send-PSGelfUDPFromObject -GelfServer graylog -Port 12202
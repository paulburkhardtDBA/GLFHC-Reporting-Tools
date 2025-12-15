Get-Content "C:\Code\Settings.ini" | foreach-object -begin {$h=@{}} -process { $k = [regex]::split($_,'='); if(($k[0].CompareTo("") -ne 0) -and ($k[0].StartsWith("[") -ne $True)) { $h.Add($k[0], $k[1]) } }
$server        = $h.Get_Item("centralServer")
$inventoryDB   = $h.Get_Item("inventoryDB")

if($server.length -eq 0){
    Write-Host "You must provide a value for the 'centralServer' in your Settings.ini file!!!" -BackgroundColor Red
    exit
}
if($inventoryDB.length -eq 0){
    Write-Host "You must provide a value for the 'inventoryDB' in your Settings.ini file!!!" -BackgroundColor Red
    exit
}

$mslExistenceQuery = "
SELECT Count(*) FROM dbo.sysobjects where id = object_id(N'[inventory].[MasterServerList]') and OBJECTPROPERTY(id, N'IsTable') = 1
"
$result = Invoke-Sqlcmd -Query $mslExistenceQuery -Database $inventoryDB -ServerInstance $server -ErrorAction Stop 

if($result[0] -eq 0){
    Write-Host "The table [inventory].[MasterServerList] wasn't found!!!" -BackgroundColor Red 
    exit
}

$enoughInstancesInMSLQuery = "
SELECT COUNT(*) FROM inventory.MasterServerList WHERE is_active = 1
"
$result = Invoke-Sqlcmd -Query $enoughInstancesInMSLQuery -Database $inventoryDB -ServerInstance $server -ErrorAction Stop 

if($result[0] -eq 0){
    Write-Host "There are no active instances registered to work with!!!" -BackgroundColor Red 
    exit
}

if ($h.Get_Item("username").length -gt 0 -and $h.Get_Item("password").length -gt 0) {
    $username   = $h.Get_Item("username")
    $password   = $h.Get_Item("password")
}

#Function to execute queries (depending on if the user will be using specific credentials or not)
function Execute-Query([string]$query,[string]$database,[string]$instance,[int]$trusted){
    if($trusted -eq 1){ 
        try{
            Invoke-Sqlcmd -Query $query -Database $database -ServerInstance $instance -ErrorAction Stop
        }
        catch{
            [string]$message = $_
            $errorQuery = "INSERT INTO monitoring.ErrorLog VALUES((SELECT serverId FROM inventory.MasterServerList WHERE CASE instance WHEN 'MSSQLSERVER' THEN server_name ELSE CONCAT(server_name,'\',instance) END = '$($instance)'),'Get-MSSQL-Instance-BufferPool','"+$message.replace("'","''")+"',GETDATE())"
            Invoke-Sqlcmd -Query $errorQuery -Database $inventoryDB -ServerInstance $server -ErrorAction Stop
        }
    }
    else{
        try{
            Invoke-Sqlcmd -Query $query -Database $database -ServerInstance $instance -Username $username -Password $password -ErrorAction Stop
        }
        catch{
            [string]$message = $_
            $errorQuery = "INSERT INTO monitoring.ErrorLog VALUES((SELECT serverId FROM inventory.MasterServerList WHERE CASE instance WHEN 'MSSQLSERVER' THEN server_name ELSE CONCAT(server_name,'\',instance) END = '$($instance)'),'Get-MSSQL-Instance-BufferPool','"+$message.replace("'","''")+"',GETDATE())"
            Invoke-Sqlcmd -Query $errorQuery -Database $inventoryDB -ServerInstance $server -ErrorAction Stop
        }
    }
}

######################################
#BufferPool monitoring table creation#
######################################
$bufferPoolMonitoringTableQuery = "
IF NOT EXISTS (SELECT * FROM dbo.sysobjects where id = object_id(N'[monitoring].[BufferPool]') and OBJECTPROPERTY(id, N'IsTable') = 1)
BEGIN
CREATE TABLE [monitoring].[BufferPool](
    [serverId]                  [INT]NOT NULL,
    [database_name]             [VARCHAR](128) NOT NULL,
    [db_buffer_MB]              [BIGINT] NOT NULL,
    [db_buffer_percent]         [DECIMAL](10,2) NOT NULL,
    [clean_pages]               [BIGINT] NOT NULL,
    [dirty_pages]               [BIGINT] NOT NULL,
    [data_collection_timestamp] [DATETIME] NOT NULL

    CONSTRAINT PK_BufferPoolMonitoring PRIMARY KEY (serverId,database_name),
    CONSTRAINT FK_BufferPoolMonitoring_MasterServerList FOREIGN KEY (serverId) REFERENCES inventory.MasterServerList(serverId) ON DELETE NO ACTION ON UPDATE NO ACTION,

) ON [PRIMARY]
END
"
Execute-Query $bufferPoolMonitoringTableQuery $inventoryDB $server 1

#TRUNCATE the monitoring.BufferPool table to always store a fresh copy of the information from all the instances
Execute-Query "TRUNCATE TABLE monitoring.BufferPool" $inventoryDB $server 1

#Select the instances from the Master Server List that will be traversed
$instanceLookupQuery = "
SELECT
        serverId,
        trusted,
		CASE instance 
			WHEN 'MSSQLSERVER' THEN server_name                                   
			ELSE CONCAT(server_name,'\',instance)
		END AS 'instance',
		CASE instance 
			WHEN 'MSSQLSERVER' THEN ip                                   
			ELSE CONCAT(ip,'\',instance)
		END AS 'ip',
        CONCAT(ip,',',port) AS 'port'
FROM inventory.MasterServerList
WHERE is_active = 1
"
$instances = Execute-Query $instanceLookupQuery $inventoryDB $server 1

#For each instance, fetch the desired information
$bufferPoolInformationQuery = "
DECLARE @buffer_pages INT;

SELECT @buffer_pages = cntr_value
FROM sys.dm_os_performance_counters 
WHERE RTRIM(object_name) LIKE '%Buffer Manager'
  AND counter_name = 'Database Pages';

WITH buffer AS(
SELECT 
		database_id, 
		COUNT_BIG(*) AS 'db_buffer_pages', 
        SUM(CASE 
             WHEN (is_modified = 1 ) THEN 0 
             ELSE 1 
            END) AS 'clean_pages',
		SUM(CASE 
             WHEN (is_modified = 1 ) THEN 1 
             ELSE 0 
            END) AS 'dirty_pages'
FROM sys.dm_os_buffer_descriptors
GROUP BY database_id)

SELECT
	CASE [database_id] 
		WHEN 32767 THEN 'Resource DB' 
		ELSE DB_NAME([database_id]) 
	END AS 'database_name',
	CONVERT(DECIMAL(10,2),db_buffer_pages / 128.0) AS 'db_buffer_MB',
	CONVERT(DECIMAL(10,2), db_buffer_pages * 100.0 / @buffer_pages) AS 'db_buffer_percent',
	clean_pages,
	dirty_pages
FROM buffer
ORDER BY db_buffer_MB DESC
"

foreach ($instance in $instances){
   if($instance.trusted -eq 'True'){$trusted = 1}else{$trusted = 0}
   $sqlInstance = $instance.instance

   #Go grab the BufferPool information for the instance
   Write-Host "Fetching BufferPool information from instance" $instance.instance
   
   #Special logic for cases where the instance isn't reachable by name
   try{
        $results = Execute-Query $bufferPoolInformationQuery "master" $sqlInstance $trusted
   }
   catch{
        $sqlInstance = $instance.ip
        [string]$message = $_
        $query = "INSERT INTO monitoring.ErrorLog VALUES("+$instance.serverId+",'Get-MSSQL-Instance-BufferPool','"+$message.replace("'","''")+"',GETDATE())"
        Execute-Query $query $inventoryDB $server 1

        try{  
            $results = Execute-Query $bufferPoolInformationQuery "master" $sqlInstance $trusted
        }
        catch{
            $sqlInstance = $instance.port
            [string]$message = $_
            $query = "INSERT INTO monitoring.ErrorLog VALUES("+$instance.serverId+",'Get-MSSQL-Instance-BufferPool','"+$message.replace("'","''")+"',GETDATE())"
            Execute-Query $query $inventoryDB $server 1

            try{
                $results = Execute-Query $bufferPoolInformationQuery "master" $sqlInstance $trusted
            }
            catch{
                [string]$message = $_
                $query = "INSERT INTO monitoring.ErrorLog VALUES("+$instance.serverId+",'Get-MSSQL-Instance-BufferPool','"+$message.replace("'","''")+"',GETDATE())"
                Execute-Query $query $inventoryDB $server 1
            }
        }
   }
   
   #Perform the INSERT in the monitoring.BufferPool only if it returns information
   if($results.Length -ne 0){

      #Build the insert statement
      $insert = "INSERT INTO monitoring.BufferPool VALUES"
      foreach($result in $results){    
         $insert += "
         (
          '"+$instance.serverId+"',
          '"+$result['database_name']+"',
           "+$result['db_buffer_MB']+",
           "+$result['db_buffer_percent']+",
           "+$result['clean_pages']+",
           "+$result['dirty_pages']+",
          GETDATE()
         ),
         "
       }
       Execute-Query $insert.Substring(0,$insert.LastIndexOf(',')) $inventoryDB $server 1
   }
}

Write-Host "Done!"
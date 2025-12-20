
#################################################################################################################
# PREREQUISITES
#################################################################################################################

#Load the OracleClient Assembly
[System.Reflection.Assembly]::LoadWithPartialName("System.Data.OracleClient") | out-null

# This function sends an email when given the parameters of email message body, and email priority 
#Function to send email
function Send-Email {
    param (
        $SubjectLine,
        $Message
    )

    $EmailRecipientList = "ufuoma_ikporo@dynamicrisk.net", "daniel_cheung@dynamicrisk.net", "ravinder_singh@dynamicrisk.net", "Hely_Bhagat@dynamicrisk.net"

    #Construct and send the email message
    Send-MailMessage `
    -To $EmailRecipientList `
    -From "HP9000@dynamicrisk.net" `
    -Subject $SubjectLine `
    -priority "High" `
    -SmtpServer "dynamicrisk-net.mail.protection.outlook.com" `
    -Body $Message
}

$StartTime = Get-Date

Write-Output "----------------------------------------------------------------------------"
Write-Output "`r`nScript Executed on: $StartTime`r`n"

############################################# SQL SERVER  ##########################################################

#List of SQL Server database servers
$ServerList = @('SQL2014EXT', 'DRASSQL2016', 'DRASSQL2017', 'DRASSQL2019',
                 '10.100.1.57', 'CTSQL01.DRAS.LOCAL', 'IRAS-PREP-SQL01')#, SQLDEVPREPROD, 'DRASSQL2022')

#Check if each server is up and running and send an email if the server is down
foreach ($Server in $ServerList)
{
    $StoppedServices = $null
    $StoppedServicesList = $null
    $Message = $null
    $SubjectLine = $null
    $Result = $null

    $Result = Ping $Server
    Write-Host "$Result`r`n`r`n"

    if (($result -match "Request timed out*" -and $result -match "Received = 0") -or $Result -match "Destination host unreachable")
    {
        $SubjectLine = "**URGENT** $Server Server Host Connection Test Failed"
        $Message = "`r`nAn attempt to establish a connection with the $Server server host has failed. Database users and applications may currently be unable to connect to the database(s) located on this server. "
        $Message += "This might be due to network connectivity issues (i.e dropped packets, VPN) or the server host may be down.`r`n`r`nContact your System Administrator to resolve the issue.`r`n"

        Send-Email -SubjectLine $SubjectLine -Message $Message
        continue
    }

    
    #List of database services that are stopped but should be running
    try{
    $StoppedServices = Get-Service -ComputerName $Server | `
    Where-Object {$_.DisplayName -like "SQL Server (MSSQLSERVER)" -or $_.DisplayName -like "SQL*CEIP*" -or $_.DisplayName -like "SQL*Writer*" -and $_.Status -eq "Stopped"} | Select-Object DisplayName
    }
    catch {
    }
    #Convert Object List into a string
    if ($null -ne $StoppedServices)
    {
        $StoppedServicesList = $StringList = [system.String]::Join("`r`n", $StoppedServices.DisplayName) + "`r`n"
    }

    #Check if database service is running
    if ("SQL Server (MSSQLSERVER)" -in $StoppedServices.DisplayName)
    {    
       $SubjectLine = "**URGENT** $Server DATABASE is DOWN"
        $Message = "`r`nThe $Server Database is down. Database users and applications are currently unable to connect to the $Server database(s) or access database resources. "
        $Message += "`r`n`r`nPossible Fixes:`r`n`r`n1. The Services listed below need to be running but are currently stopped. Connect to the $Server server and go to Windows Services to start up the services listed below.`r`n"
        $Message += "`r`n" + $StoppedServicesList

        Send-Email -SubjectLine $SubjectLine -Message $Message 
    }
    elseif ($null -ne $StoppedServices)
    {
    
        $SubjectLine = "**URGENT** $Server Service(s) is Down"
        $Message = "`r`nOne or more vital database services for the $Server database server is down. Database users and applications may not be able to connect to the $Server database(s) or obtain to certain database resources. "
        $Message += "`r`n`r`nPossible Fixes:`r`n`r`n1. The Services listed below need to be running but are currently stopped. Connect to the $Server server and go to Windows Services to start up the services listed below.`r`n"
        $Message += "`r`n" + $StoppedServicesList

        Send-Email -SubjectLine $SubjectLine -Message $Message 
    }


}#end of foreach-loop

######################################################### FOR ORACLE SERVER ##################################################

<#
    This Portion of the script only works correctly if 
    1) the servername and database server name are entered correctly
    2) there is a user on each database with username = DBBACKUPUSER and password = dbbackupuser
#><#

$ServerList = $arr = @(
    [PSCustomObject]@{ServerName = 'ORA12CEXT.eddyfindt.com';  TNSName = 'DRASORA12CEXT'}
    [PSCustomObject]@{ServerName = 'DRASORA19C.eddyfindt.com';  TNSName = 'DRASORA19C'}
    [PSCustomObject]@{ServerName = 'DRASORA19C22.eddyfindt.com';  TNSName = 'DRASORA19C22'}
   # [PSCustomObject]@{ServerName = 'ORA12CMT.eddyfindt.com';  TNSName = 'etp.eddyfindt.com'}

)

foreach ($item in $ServerList)
{
    $StoppedServices = $null
    $StoppedServicesList = $null
    $Message = $null
    $SubjectLine = $null
    $OracleDBProcess = $null

    $CheckDBMode = 0

    $FullServerName = $item.ServerName
    $TNSAlias = $Item.TNSName
    $Server = $item.ServerName.Substring(0, $item.ServerName.IndexOf("."))
    $DBName = $TNSAlias

    $result = ping $FullServerName
   
    if ($result -match "Request timed out*" -and $result -match "Received = 0")
    {
        Write-Host $Result
        $SubjectLine = "**URGENT** $Server Server Connection Test Failed"
        $Message = "`r`nAn attempt to establish a connection with the $Server server host has failed. Database users and applications may currently be unable to connect to the database(s) located on this server. "
        $Message += "This might be due to network connectivity issues (i.e dropped packets, VPN) or the server host may be down.`r`n`r`nContact your System Administrator to resolve the issue.`r`n"

        Send-Email -SubjectLine $SubjectLine -Message $Message 
        continue
    }
    
    #Get a list of the essential Oracle database services that are stopped. 
    try{
        $StoppedServices = Get-Service -ComputerName $Server | `
        Where-Object {$_.DisplayName -like "OracleService*" -or $_.DisplayName -like "OracleOraDB*Home*" -or $_.DisplayName -like "Oracle*Writer*" -and $_.Status -eq "Stopped"} | Select-Object DisplayName
    }
    catch{
       
    }

    #Convert Object List into a string
    if ($null -ne $StoppedServices)
    {
        $StoppedServicesList = $StringList = [system.String]::Join("`r`n", $StoppedServices.DisplayName) + "`r`n"
    }

    #Check if database service is running
    if ($StoppedServices.DisplayName -like "OracleService*")
    {
    
        $SubjectLine = "**URGENT** $DBName Database Server is Down"
        $Message = "`r`nThe $DBName Database server is down. Database users and applications are currently unable to connect to the $DBName database or access database resources. "
        $Message += "`r`n`r`nPossble Fixes:`r`n`r`n1. The Service(s) listed below are currently stopped but need to be running for normal database operations. Connect to the $DBName Server, go to Windows Services, and start up the following services.`r`n"
        $Message += "`r`n" + $StoppedServicesList

        Send-Email -SubjectLine $SubjectLine -Message $Message 
    }
    elseif ($StoppedServices.DisplayName -like "Oracle*TNS*")
    {
        $SubjectLine = "**URGENT** $DBName Database LISTENER is Down"
        $Message = "`r`nThe $DBName Database listener is down. Database users and applications are currently unable to connect to the $DBName database or access database resources. "
        $Message += "`r`n`r`nPossble Fix:`r`n`r`n1. The Service(s) listed below are currently stopped but need to be running for normal database operations. Connect to the $Server Server, go to Windows Services, and start up the following services.`r`n"
        $Message += "`r`n" + $StoppedServicesList

        Send-Email -SubjectLine $SubjectLine -Message $Message 
    }
    elseif ($null -ne $StoppedServices)
    {
    
        $SubjectLine = "**URGENT** $Server Database Service(s) NOT Running"
        $Message = "`r`nOne or more vital Oracle database services are currently not running on the $Server server. Database users and applications may not be able to connect to the $DBName database or perform certain database operations. "
        $Message += "`r`n`r`nPossble Fix:`r`n`r`nThe Services listed below need to be running but are currently stopped. Connect to the $Server server and go to Windows Services to start up the services listed below.`r`n"
        $Message += "`r`n" + $StoppedServicesList

        Send-Email -SubjectLine $SubjectLine -Message $Message 
    } #end of elseif-statement
    
    # Check if the database is open
    if (($StoppedServices.DisplayName -like "OracleService*" -or $StoppedServices.DisplayName -like "Oracle*TNS*") -eq $false)
    {

        try
        {
            #PowerShell object to store the results from an SQL query
            $Query = "SET PAGES 0
                      SET FEEDBACK OFF;
                      SELECT 1 FROM DUAL;"

            $CheckDBMode = $Query | SQLPLUS -silent "DBBACKUPUSER/dbbackupuser@$TNSAlias"
           
        }
        catch
        {
            $CheckDBMode = 0
        }

        if ($CheckDBMode = 0)
        {
            $CheckDBMode = "NO"
        }
        else
        {
            $CheckDBMode = "YES"
        }

        write-host "TNSName: $TNSAlias     CanConnect: $CheckDBMode"
         
        if($CheckDBMode -eq 0 -or $CheckDBMode -like "ERROR*")
        {
            $SubjectLine = "**URGENT** $DBName Failed Connection Test"
            $Message = "`r`nThe $DBName database failed a connection test. Database users and applications may not be able to connect to the $DBName database. "
            $Message += "`r`n`r`nPossble Fixes: "
            $Message += "`r`n`r`n1. Check that the $Server server is still up and running"
            $Message += "`r`n`r`n2. Connect to the database with 'SYSDBA' privileges from the $Server server. Then use the command line to either startup the database, or set the database to open mode."
            $Message += "`r`n`r`n3. Make sure the database service is registered with the listener. Set the database service to dynamically register with the listener."
            $Message += "`r`n`r`n4. Check that the connection testing script is located on a server with an updated TNSnames file.`r`n"
            $Message += "`r`n`r`n5. Make sure the DBBACKUPUSER user exists on the database with with the correct password.`r`n"
            
            if ($StoppedServicesList -ne $null)
            {
                $Message += "`r`n`r`nThe Services listed below are currently stopped but need to be running for normal database operations.`r`n"
                $Message += "`r`n" + $StoppedServicesList
            }

            Send-Email -SubjectLine $SubjectLine -Message $Message 
        }
    
    } #end of if-statement
    
} #end of foreach-loop
#>
$EndTime = Get-Date
$Duration = ($EndTime - $StartTime).ToString("hh'hr:'mm'min:'ss'sec'")

Write-Host "The script was sucessfully completed"
Write-Host "Duration: $Duration"  

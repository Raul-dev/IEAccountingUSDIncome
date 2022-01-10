# SPDX-license-identifier: Apache-2.0
##############################################################################
# Copyright (c) 2021 Raul
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################
#Accounting for russian Individual Entrepreneur with an income in USD
#IEAccountingUSDIncome
# ./db.ps1 -DBname "IEAccountingUSDIncome" -ServerName "win191c" -SQLuser "sa"  -SQLpwd "PWD123123"
# ./db.ps1 -DBname "IEAccountinginUSD" -ExcelIncomeBook "D:\Work\Payment\2021\Declaration.xlsm"  -ExcelSheetCmd "'Select * from [Income$]'"
Param (
    [parameter(Mandatory=$false)][string]$DBname="IEAccountingUSDIncome",
    [parameter(Mandatory=$false)][string]$ServerName="localhost",
    [parameter(Mandatory=$false)][string]$ExcelIncomeBook="",
    [parameter(Mandatory=$false)][string]$ExcelSheetCmd="",
    [parameter(Mandatory=$false)][string]$RecreateDatabase=$true,
    [parameter(Mandatory=$false)][string]$SQLuser="",
    [parameter(Mandatory=$false)][string]$SQLpwd=""
  )
function ApplySqlScriptFromFolder {

  param (
      $Folder
  )
  try{
  
	  $Files = Get-ChildItem $Folder
	  Write-Host "Step folder: "$Folder 

	  for ($i=0; $i -lt $Files.count; $i++){
		$SqlFile = $Folder+"\"+$Files[$i]
		
		Write-Host "Step"$i": "$SqlFile
		IF ($SQLuser.length -eq 0){
			sqlcmd -S $ServerName  -d $DBname  -i $Sqlfile -h -1 | Out-Null
        } else {
	        sqlcmd -U $SQLuser -P $SQLpwd -S $ServerName  -d $DBname  -i $Sqlfile -h -1 | Out-Null
		    }
	  }
	  
  } catch { 
    Write-Host "Exec sqlcmd: An sql error occurred " -fore red
    Write-Host $_ -fore red
	return -1
	
  }
  return 0
}
function IsDatabaseExists {
 try{
	
	  $SqlCmd = "SET NOCOUNT ON; SELECT res=count(*) FROM sys.databases WHERE name='"+$DBname+"'"
  
	  IF ($SQLuser.length -eq 0){
		  $DataCount1 = sqlcmd -S $ServerName  -d master  -Q $SqlCmd -h -1
	  } else {
		  $DataCount1 = sqlcmd -U $SQLuser -P $SQLpwd -S $ServerName  -d master  -Q $SqlCmd -h -1
	  }	  

	  $DataCount = $DataCount1.Trim()
	  IF ($DataCount -eq 0){
		  return 0 
	  }else{
		  return 1 
	  }
	  
  } catch { 
    Write-Host "Exec sqlcmd: An sql error occurred " -fore red
    Write-Host $_ -fore red
	return -1
	
  }
  return 0
}
$ProjectPath = Convert-Path .

$execps1 = $ProjectPath+"\DropDatabase.ps1"

IF ($RecreateDatabase -eq $true ){
	& $execps1 $DBname $ServerName $SQLuser $SQLpwd
}

Write-Host "Database name: "$DBname
Write-Host "DB Server: "$ServerName

$res = IsDatabaseExists
IF ($res -eq 0){
  $FolderLocation = $ProjectPath +'\db\'
  IF (!(Test-Path $FolderLocation)){
    New-Item -ItemType "directory" -Path $FolderLocation -ErrorAction SilentlyContinue
    $acl = Get-Acl $FolderLocation
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("everyone","FullControl","Allow")
    $acl.SetAccessRule($accessRule)
    $acl | Set-Acl $FolderLocation
  }


  Write-Host "local DB folder location: " $FolderLocation
  $DefaultDataDisk = $FolderLocation.Substring(0,1) 
  $FolderLocation = $FolderLocation.Substring(2)


  IF ($SQLuser.length -eq 0){

    sqlcmd -S $ServerName  -d master -v DatabaseName="$DBname" -v DefaultFilePrefix="$DBname" -v DefaultDataDisk=$DefaultDataDisk -v DefaultDataPath="$FolderLocation" -v DefaultLogPath="$FolderLocation" -i [001_CreateDatabase].sql
  } else {
    $DefaultDataDisk="C"
    $FolderLocation="\Program Files\Microsoft SQL Server\MSSQL15.MSSQL_2019\MSSQL\DATA\"
    $FolderLocation="\Temp\"
    sqlcmd -U $SQLuser -P $SQLpwd -S $ServerName  -d master -v DatabaseName="$DBname" -v DefaultFilePrefix="$DBname" -v DefaultDataDisk="E" -v DefaultDataPath="$FolderLocation" -v DefaultLogPath="$FolderLocation" -i [001_CreateDatabase].sql
  }
  $res = IsDatabaseExists
  IF ($res -eq 0){
	  Write-Host "Database "$DBname" did not create."
    exit -1
  }else{
    Write-Host "Database "$DBname" created successfully."
  }
}else{
   Write-Host "Database "$DBname" exists."
 }

try{
   
  $FolderLocation = $ProjectPath +'\Tables'

  $RetCode = ApplySqlScriptFromFolder $FolderLocation
  Write-Host "RetCode:"$RetCode

  $FolderLocation = $ProjectPath +'\Procedures'
  $RetCode = ApplySqlScriptFromFolder $FolderLocation
  Write-Host "RetCode:"$RetCode
  

  $SqlCmd = "EXEC [meta].[sp_InitDataBase]"
  Write-Host $SqlCmd
  IF ($SQLuser.length -eq 0){
	  sqlcmd -S $ServerName  -d $DBname  -Q $SqlCmd 
  } else {
	  sqlcmd -U $SQLuser -P $SQLpwd -S $ServerName  -d $DBname  -Q $SqlCmd 
  }
  
  $FolderLocation = $ProjectPath +'\IncomeBook.xlsx'
  IF ($ExcelIncomeBook.length -eq 0){
	$ExcelIncomeBook = $FolderLocation
  }
  IF ($ExcelSheetCmd.length -eq 0){
	$ExcelSheetCmd = "'Select * from [Sheet1$]'"
  }
  
  
  $SqlCmd = "INSERT [meta].[ConfigApp] (Parameter, StrValue) VALUES( 'ExcelFileIncomeBook','"+$ExcelIncomeBook+"')
             UPDATE [meta].[ConfigApp] SET 
				StrValue = " + $ExcelSheetCmd + "
			 WHERE Parameter = 'ExcelFileIncomeBookCmd'"
  Write-Host $SqlCmd
  IF ($SQLuser.length -eq 0){
	  sqlcmd -S $ServerName  -d $DBname  -Q $SqlCmd 
  } else {
	  sqlcmd -U $SQLuser -P $SQLpwd -S $ServerName  -d $DBname  -Q $SqlCmd 
  }

  
  Write-Host "Start Unit Test ....]"
  IF ($SQLuser.length -eq 0){
    sqlcmd -S $ServerName  -d $DBname  -Q "exec [uts].[usp_UnitTest]" | Out-Null
    sqlcmd -S $ServerName  -d $DBname  -Q "SET NOCOUNT ON; SELECT * FROM (SELECT SUBSTRING(TestName,1,60) as TestName,CAST(SUBSTRING((CASE WHEN LEN(Error) = 0 THEN 'succeeded' ELSE Error END),1,10) as varchar(10)) Error,datestamp FROM [uts].[ResultUnitTest]) tmp" 
  } else {
    sqlcmd -U $SQLuser -P $SQLpwd -S $ServerName  -d $DBname  -Q "exec [uts].[usp_UnitTest]" | Out-Null
    sqlcmd -U $SQLuser -P $SQLpwd -S $ServerName  -d $DBname  -Q "SET NOCOUNT ON; SELECT * FROM (SELECT SUBSTRING(TestName,1,60) as TestName,CAST(SUBSTRING((CASE WHEN LEN(Error) = 0 THEN 'succeeded' ELSE Error END),1,10) as varchar(10)) Error,datestamp FROM [uts].[ResultUnitTest]) tmp" 
  }
  
  $SqlCmd = "SET NOCOUNT ON; SELECT res=count(*) FROM [uts].[ResultUnitTest] WHERE Error <> ''"
  
  IF ($SQLuser.length -eq 0){
	  $DataCount1 = sqlcmd -S $ServerName  -d $DBname  -Q $SqlCmd -h -1
  } else {
	  $DataCount1 = sqlcmd -U $SQLuser -P $SQLpwd -S $ServerName  -d $DBname  -Q $SqlCmd -h -1
  }
  
  $DataCount = $DataCount1.Trim()
  Write-Host "Error test count: " $DataCount
  

}
catch {
  
  Write-Host "An error occurred:" -fore red
  Write-Host $_ -fore red
  Write-Host "Stack:"
  Write-Host $_.ScriptStackTrace
}

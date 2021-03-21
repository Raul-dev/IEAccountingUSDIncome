# SPDX-license-identifier: Apache-2.0
##############################################################################
# Copyright (c) 2021 Raul
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################
Param (
    [parameter(Mandatory=$false)][string]$DBname="IEAccountinginUSD",
    [parameter(Mandatory=$false)][string]$ServerName="localhost",
    [parameter(Mandatory=$false)][string]$SQLuser="",
    [parameter(Mandatory=$false)][string]$SQLpwd=""
  )

try{

  Write-Host  "Drop database: '"$DBname"'"
  
  
  $SqlCmd = "SET NOCOUNT ON; SELECT res=count(*) FROM sys.databases WHERE name='"+$DBname+"'"
  
  IF ($SQLuser.length -eq 0){
    $DataCount1 = sqlcmd -S $ServerName  -d master  -Q $SqlCmd -h -1
  } else {
    $DataCount1 = sqlcmd -U $SQLuser -P $SQLpwd -S $ServerName  -d master  -Q $SqlCmd -h -1
  }	  

  $DataCount = $DataCount1.Trim()
  Write-Host "Record count: " $DataCount
  if($DataCount -ne 0) {
	  Write-Host "Drop database  "$DBname
    $SqlCmd = "
    DECLARE	@Spid INT
    DECLARE	@ExecSQL VARCHAR(255)
    
    DECLARE	KillCursor CURSOR LOCAL STATIC READ_ONLY FORWARD_ONLY
    FOR
    SELECT	DISTINCT SPID
    FROM	MASTER..SysProcesses
    WHERE	DBID = DB_ID('"+$DBname+"')
    
    OPEN	KillCursor
    
    -- Grab the first SPID
    FETCH	NEXT
    FROM	KillCursor
    INTO	@Spid
    
    WHILE	@@FETCH_STATUS = 0
      BEGIN
        SET		@ExecSQL = 'KILL ' + CAST(@Spid AS VARCHAR(50))
    
        EXEC	(@ExecSQL)
    
        -- Pull the next SPID
            FETCH	NEXT 
        FROM	KillCursor 
        INTO	@Spid  
      END
    
    CLOSE	KillCursor
    
    DEALLOCATE	KillCursor
    GO
    ALTER DATABASE "+$DBname+"
      SET SINGLE_USER;
      GO
      DROP DATABASE "+$DBname
	
	IF ($SQLuser.length -eq 0){
	  $DataCount1 = sqlcmd -S $ServerName  -d master  -Q $SqlCmd -h -1
    } else {
	  $DataCount1 = sqlcmd -U $SQLuser -P $SQLpwd -S $ServerName  -d master  -Q $SqlCmd -h -1
	}	  
	  
  }


}
catch {
  Write-Host "An error occurred:" -fore red
  Write-Host $_ -fore red
  exit -1
}
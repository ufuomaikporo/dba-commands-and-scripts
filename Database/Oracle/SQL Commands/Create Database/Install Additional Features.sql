/*
This script instal additional features after the database has been created
*/

SET VERIFY OFF
ACCEPT sysPassword CHAR PROMPT 'Enter the SYS user password: ' HIDE
SPOOL %ORACLE_BASE%\admin\AdditionalFeatureInstall_SPOOLFile.log REPLACE

--************************************** INSTALL ORACLE XML DATABASE *************************************


 /*
	This is automatically created after issuing the CATALOG.SQL and CATPROC.SQL scripts  
 https://docs.oracle.com/cd/B13789_01/appdev.101/b10790/appaman.htm#CACGFBEI
*/

 -- @?\rdbms\admin\catqm.sql ChangeOnInstall SYSAUX TEMP
 
 -- -- Resolve any invalid objects
-- @?/rdbms/admin/utlrp.sql

--************************************** INSTALL ORACLE TEXT *************************************

/* 
1) This feature needs to be installed to enable the geodatabase feature through ArcGis Pro

https://docs.oracle.com/cd/E57425_01/121/DFSIG/oracle-text.htm#DFSIG269
*/

CONNECT sys/"&&sysPassword" as sysdba

-- Set the password, default tablespace, and default temporary tablespace for the CTXSYS user following the script path (nolock unlocks the account)
@%ORACLE_HOME%/ctx/admin/catctx.sql CTXSYS SYSAUX TEMP NOLOCK;

CONNECT CTXSYS/CTXSYS
@%ORACLE_HOME%/ctx/admin/defaults/drdefus.sql;

-- Resolve any invalid objects
@?/rdbms/admin/utlrp.sql

--************************************** INSTALL JServer JAVA Virtual Machine *************************************

CONNECT sys/"&&sysPassword" as sysdba

ALTER SYSTEM SET "_system_trig_enabled" = FALSE SCOPE=memory;
@?/javavm/install/initjvm.sql
@?/xdk/admin/initxml.sql
@?/xdk/admin/xmlja.sql
@?/rdbms/admin/catjava.sql
SHUTDOWN IMMEDIATE;
STARTUP

 -- Resolve any invalid objects
@?/rdbms/admin/utlrp.sql

--************************************** INSTALL ORACLE SPATIAL COMPONENTS *************************************

CONNECT sys/"&&sysPassword" as sysdba

-- STEP 1) Create MDSYS user
CREATE USER MDSYS IDENTIFIED BY "&&MDSYSpassword" DEFAULT TABLESPACE SYSAUX ACCOUNT LOCK;

-- STEP 2) Grant privileges to MDSYS user
@?/md/admin/mdprivs.sql

-- STEP 3) Install Spatial 
@?/md/admin/mdinst.sql

-- STEP 4) Resolve any invalid objects
@?/rdbms/admin/utlrp.sql

SPOOL OFF
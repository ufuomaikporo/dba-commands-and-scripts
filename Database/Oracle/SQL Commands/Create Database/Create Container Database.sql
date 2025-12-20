-- Prompt user to set the SYS and SYSTEM passwords
SET VERIFY OFF
ACCEPT sysPassword CHAR PROMPT 'Enter new password for SYS: ' HIDE
ACCEPT systemPassword CHAR PROMPT 'Enter new password for SYSTEM: ' HIDE

SPOOL %ORACLE_BASE%\admin\DBCreationSpoolFile.log REPLACE

------------------------------------------------------ CREATE DATABASE -----------------------------------------------------------

-- Be sure to create the file directories below before issuing the CREATE DATABASE command
CREATE DATABASE COCDB -- 8 character limit for database name
   USER SYS IDENTIFIED BY "&&sysPassword"
   USER SYSTEM IDENTIFIED BY "&&systemPassword"
LOGFILE GROUP 1 ('C:\app\Oracle\oradata\COCDB\REDO01A.LOG',
			 'D:\app\Oracle\oradata\COCDB\REDO01B.LOG',
			 'E:\app\Oracle\oradata\COCDB\REDO01C.LOG') SIZE 200M,
		GROUP 2 ('C:\app\Oracle\oradata\COCDB\REDO02A.LOG',
				 'D:\app\Oracle\oradata\COCDB\REDO02B.LOG',
				 'E:\app\Oracle\oradata\COCDB\REDO02C.LOG') SIZE 200M,
		GROUP 3 ('C:\app\Oracle\oradata\COCDB\REDO03A.LOG',
				 'D:\app\Oracle\oradata\COCDB\REDO03B.LOG',
				 'E:\app\Oracle\oradata\COCDB\REDO03C.LOG') SIZE 200M
MAXINSTANCES 1
MAXLOGHISTORY 1
MAXLOGFILES 16
MAXLOGMEMBERS 3
MAXDATAFILES 1024
CHARACTER SET AL32UTF8
NATIONAL CHARACTER SET AL16UTF16
EXTENT MANAGEMENT LOCAL
DATAFILE 'F:\app\Oracle\oradata\COCDB\SYSTEM01.DBF' 
	SIZE 880 REUSE AUTOEXTEND ON NEXT 70M MAXSIZE UNLIMITED
SYSAUX DATAFILE 'F:\app\Oracle\oradata\COCDB\SYSAUX01.DBF' 
	SIZE 500M REUSE	AUTOEXTEND ON NEXT 50M MAXSIZE UNLIMITED
DEFAULT TABLESPACE users
DATAFILE 'E:\app\Oracle\ORA12CEXT\oradata\users01.dbf'
	SIZE 500M REUSE AUTOEXTEND ON NEXT 100M MAXSIZE UNLIMITED
DEFAULT TEMPORARY TABLESPACE TEMP 
TEMPFILE 'G:\app\Oracle\oradata\COCDB\TEMP01.DBF' 
   SIZE 100M REUSE AUTOEXTEND ON NEXT 20M MAXSIZE UNLIMITED
UNDO TABLESPACE "UNDOTBS1" DATAFILE 'F:\app\Oracle\oradata\COCDB\UNDOTBS01.DBF' 
   SIZE 700M REUSE AUTOEXTEND ON NEXT 200M MAXSIZE UNLIMITED
  
-- Add Pluggable database
ENABLE PLUGGABLE DATABASE
SEED file_name_convert=('F:\app\Oracle\oradata\COCDB\SYSTEM01.DBF','F:\app\Oracle\oradata\COCDB\pdbseed\SYSTEM01.DBF',
                        'F:\app\Oracle\oradata\COCDB\SYSAUX01.DBF','F:\app\Oracle\oradata\COCDB\pdbseed\SYSAUX01.DBF',
                        'G:\app\Oracle\oradata\COCDB\TEMP01.DBF','G:\app\Oracle\oradata\COCDB\pdbseed\TEMP01.DBF',
                        'F:\app\Oracle\oradata\COCDB\UNDOTBS01.DBF','F:\app\Oracle\oradata\COCDB\pdbseed\UNDOTBS01.DBF');


----------------------------------- Install Oracle components in CDB$ROOT and PDB$SEED ---------------------------

CONNECT SYS/"&&SYSPASSWORD" AS SYSDBA
@?\rdbms\admin\catalog.sql
@?\rdbms\admin\catproc.sql
@?\rdbms\admin\utlrp.sql

conn system/"&&systemPassword"

@?\sqlplus\admin\pupbld.sql

CONNECT SYS/"&&SYSPASSWORD" AS SYSDBA
ALTER SESSION SET "_oracle_script"=TRUE;

ALTER PLUGGABLE DATABASE PDB$SEED OPEN READ WRITE FORCE;

ALTER SESSION SET CONTAINER = PDB$SEED;

@?\rdbms\admin\catalog.sql
@?\rdbms\admin\catproc.sql
@?\rdbms\admin\utlrp.sql

conn system/"&&systemPassword"

ALTER SESSION SET CONTAINER = PDB$SEED;

@?\sqlplus\admin\pupbld.sql

-------------------------------------------------------- Create pluggable database ----------------------------------------

CONNECT SYS/"&&SYSPASSWORD" AS SYSDBA
ALTER PLUGGABLE DATABASE PDB$SEED OPEN READ ONLY FORCE;

CREATE PLUGGABLE DATABASE acctpdb ADMIN USER acct_admin IDENTIFIED BY Or5cle#123
DEFAULT TABLESPACE users
  DATAFILE 'G:\app\Oracle\oradata\COCDB\acctpdb\USERS01.DBF' SIZE 500M 
  AUTOEXTEND ON NEXT 1M MAXSIZE UNLIMITED
FILE_NAME_CONVERT=('F:\app\Oracle\oradata\COCDB\pdbseed',
                   'F:\app\Oracle\oradata\COCDB\acctpdb',
                   'G:\app\Oracle\oradata\COCDB\pdbseed',
                   'G:\app\Oracle\oradata\COCDB\acctpdb');

-- Open pdb save state

ALTER PLUGGABLE DATABASE acctpdb OPEN;

ALTER PLUGGABLE DATABASE acctpdb SAVE STATE;

ALTER SESSION SET CONTAINER=acctpdb;

GRANT DBA TO acct_admin;

-- Create index tablespace

CREATE TABLESPACE indx
DATAFILE'G:\app\Oracle\oradata\COCDB\ACCTDB\INDEX01.DBF'
SIZE 30M REUSE AUTOEXTEND ON NEXT 1M MAXSIZE 200M;

-------------------------------------------------- Enable archive log mode ----------------------------------------------------

ALTER SYSTEM SET log_archive_dest_1 = 'LOCATION=USE_DB_RECOVERY_FILE_DEST';

ALTER SYSTEM SET log_archive_dest_2 = 'LOCATION=G:\app\Oracle\recovery_area';

SHUTDOWN IMMEDIATE

STARTUP MOUNT

ALTER DATABASE ARCHIVELOG;

ALTER DATABASE OPEN;

SPOOL OFF
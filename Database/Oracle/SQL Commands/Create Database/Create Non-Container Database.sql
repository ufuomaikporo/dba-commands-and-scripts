-- Prompt user to set the SYS and SYSTEM passwords

SET VERIFY OFF
ACCEPT sysPassword CHAR PROMPT 'Enter new password for SYS: ' HIDE
ACCEPT systemPassword CHAR PROMPT 'Enter new password for SYSTEM: ' HIDE

SPOOL %ORACLE_BASE%\admin\DBCreationSpoolFile.log REPLACE
------------------------------------------------------ CREATE DATABASE -----------------------------------------------------------

CREATE DATABASE ORA12CEX -- 8 character limit for database name
USER SYS IDENTIFIED BY "&&sysPassword"
USER SYSTEM IDENTIFIED BY "&&systemPassword"
-- Multiplexed Redo log files
LOGFILE GROUP 1 ('C:\app\Oracle\oradata\ORA12CEXT\redo01a.log',
				'E:\app\Oracle\ORA12CEXT\oradata\redo01b.log',
				'B:\Oracle\oradata\ORA12CEXT\redo01c.log') SIZE 100M,
	   GROUP 2 ('C:\app\Oracle\oradata\ORA12CEXT\redo02a.log',
				'E:\app\Oracle\ORA12CEXT\oradata\redo02b.log',
				'B:\Oracle\oradata\ORA12CEXT\redo02c.log') SIZE 100M,
	   GROUP 3 ('C:\app\Oracle\oradata\ORA12CEXT\redo03a.log',
				'E:\app\Oracle\ORA12CEXT\oradata\redo03b.log',
				'B:\Oracle\oradata\ORA12CEXT\redo03c.log') SIZE 100M
MAXLOGFILES 5
MAXLOGMEMBERS 5
MAXLOGHISTORY 1
MAXDATAFILES 100
MAXINSTANCES 1
CHARACTER SET AL32UTF8
NATIONAL CHARACTER SET AL16UTF16
EXTENT MANAGEMENT LOCAL
-- Create data files
DATAFILE 'E:\app\Oracle\ORA12CEXT\oradata\system01.dbf' 
	SIZE 880M REUSE AUTOEXTEND ON NEXT 200M MAXSIZE UNLIMITED
SYSAUX DATAFILE 'E:\app\Oracle\ORA12CEXT\oradata\sysaux01.dbf' 
	SIZE 500M REUSE AUTOEXTEND ON NEXT 100M MAXSIZE UNLIMITED
DEFAULT TABLESPACE users
DATAFILE 'E:\app\Oracle\ORA12CEXT\oradata\users01.dbf'
	SIZE 500M REUSE AUTOEXTEND ON NEXT 200M MAXSIZE UNLIMITED
DEFAULT TEMPORARY TABLESPACE TEMP
TEMPFILE 'E:\app\Oracle\ORA12CEXT\oradata\temp01.dbf'
	SIZE 100M REUSE AUTOEXTEND ON NEXT 20M MAXSIZE UNLIMITED
UNDO TABLESPACE UNDOTBS
 DATAFILE 'E:\app\Oracle\ORA12CEXT\oradata\undotbs01.dbf'
  SIZE 700M REUSE AUTOEXTEND ON NEXT 200M MAXSIZE UNLIMITED;

----------------------------------- Install Oracle components in CDB$ROOT and PDB$SEED ---------------------------

CONNECT SYS/"&&SYSPASSWORD" AS SYSDBA

@?\RDBMS\ADMIN\CATALOG.SQL
@?\RDBMS\ADMIN\CATPROC.SQL
@?\RDBMS\ADMIN\UTLRP.SQL

CONNECT SYSTEM/"&&SYSTEMPASSWORD"

@?\SQLPLUS\ADMIN\PUPBLD.SQL

SPOOL OFF
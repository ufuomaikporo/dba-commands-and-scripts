CREATE DATABASE COCDB
MAXINSTANCES 1
MAXLOGHISTORY 1
MAXLOGFILES 16
MAXLOGMEMBERS 3
MAXDATAFILES 1024
DATAFILE 'F:\app\Oracle\oradata\COCDB\SYSTEM01.DBF' SIZE 700M REUSE
  AUTOEXTEND ON NEXT  10M MAXSIZE UNLIMITED
  EXTENT MANAGEMENT LOCAL
SYSAUX DATAFILE 'F:\app\Oracle\oradata\COCDB\SYSAUX01.DBF' SIZE 500M REUSE
  AUTOEXTEND ON NEXT  10M MAXSIZE UNLIMITED
SMALLFILE DEFAULT TEMPORARY TABLESPACE TEMP TEMPFILE 'G:\app\Oracle\oradata\COCDB\TEMP01.DBF' 
   SIZE 70M REUSE
  AUTOEXTEND ON NEXT  1M MAXSIZE UNLIMITED
SMALLFILE UNDO TABLESPACE "UNDOTBS1" DATAFILE 'F:\app\Oracle\oradata\COCDB\UNDOTBS01.DBF' 
   SIZE 200M REUSE
  AUTOEXTEND ON NEXT  5M MAXSIZE UNLIMITED
CHARACTER SET AL32UTF8
NATIONAL CHARACTER SET AL16UTF16
LOGFILE GROUP 1 ('C:\app\Oracle\oradata\COCDB\REDO01A.LOG',
                 'D:\app\Oracle\oradata\COCDB\REDO01B.LOG',
                 'E:\app\Oracle\oradata\COCDB\REDO01C.LOG') SIZE 200M,
        GROUP 2 ('C:\app\Oracle\oradata\COCDB\REDO02A.LOG',
                 'D:\app\Oracle\oradata\COCDB\REDO02B.LOG',
                 'E:\app\Oracle\oradata\COCDB\REDO02C.LOG') SIZE 200M,
        GROUP 3 ('C:\app\Oracle\oradata\COCDB\REDO03A.LOG',
                 'D:\app\Oracle\oradata\COCDB\REDO03B.LOG',
                 'E:\app\Oracle\oradata\COCDB\REDO03C.LOG') SIZE 200M
USER SYS IDENTIFIED BY Or5cle#123 USER SYSTEM IDENTIFIED BY Or5cle#123
enable pluggable database
seed file_name_convert=('F:\app\Oracle\oradata\COCDB\SYSTEM01.DBF','F:\app\Oracle\oradata\COCDB\pdbseed\SYSTEM01.DBF',
                        'F:\app\Oracle\oradata\COCDB\SYSAUX01.DBF','F:\app\Oracle\oradata\COCDB\pdbseed\SYSAUX01.DBF',
                        'G:\app\Oracle\oradata\COCDB\TEMP01.DBF','G:\app\Oracle\oradata\COCDB\pdbseed\TEMP01.DBF',
                        'F:\app\Oracle\oradata\COCDB\UNDOTBS01.DBF','F:\app\Oracle\oradata\COCDB\pdbseed\UNDOTBS01.DBF');

conn \ as sysdba

-- Create the users tablespace in the CDB$ROOT

CREATE TABLESPACE users
DATAFILE'G:\app\Oracle\oradata\COCDB\USERS01.DBF'
SIZE 500M AUTOEXTEND ON NEXT 5M MAXSIZE UNLIMITED;

-- Install Oracle components in CDB$ROOT adn PDB$SEED

@?\rdbms\admin\catalog.sql
@?\rdbms\admin\catproc.sql
@?\rdbms\admin\utlrp.sql

conn system\Or5cle#123

@?\sqlplus\admin\pupbld.sql

conn \ as sysdba

ALTER SESSION SET "_oracle_script"=TRUE;

ALTER PLUGGABLE DATABASE PDB$SEED OPEN READ WRITE FORCE;

ALTER SESSION SET CONTAINER = PDB$SEED;

@?\rdbms\admin\catalog.sql
@?\rdbms\admin\catproc.sql
@?\rdbms\admin\utlrp.sql

conn system\Or5cle#123

ALTER SESSION SET CONTAINER = PDB$SEED;

@?\sqlplus\admin\pupbld.sql

-- Create pluggable database

conn \ as sysdba

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

-- Enable archive log mode

ALTER SYSTEM SET log_archive_dest_1 = 'LOCATION=USE_DB_RECOVERY_FILE_DEST';

ALTER SYSTEM SET log_archive_dest_2 = 'LOCATION=G:\app\Oracle\recovery_area';

SHUTDOWN IMMEDIATE

STARTUP MOUNT

ALTER DATABASE ARCHIVELOG;

ALTER DATABASE OPEN;

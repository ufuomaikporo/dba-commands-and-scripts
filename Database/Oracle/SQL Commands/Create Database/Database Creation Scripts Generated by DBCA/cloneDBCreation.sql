SET VERIFY OFF
connect "SYS"/"&&sysPassword" as SYSDBA
set echo on
spool C:\app\Oracle\admin\ORA12CEXT\scripts\cloneDBCreation.log append
shutdown abort;
startup nomount pfile="C:\app\Oracle\admin\ORA12CEXT\scripts\init.ora";
Create controlfile reuse set database "ORA12CEX"
MAXINSTANCES 8
MAXLOGHISTORY 1
MAXLOGFILES 16
MAXLOGMEMBERS 3
MAXDATAFILES 100
Datafile 
'&&file0',
'&&file1',
'&&file2',
'&&file3'
LOGFILE GROUP 1 ('C:\app\Oracle\oradata\ORA12CEXT\redo01A.log','E:\app\Oracle\ORA12CEXT\oradata\redo01B.log','B:\Oracle\oradata\ORA12CEXT\redo01C.log') SIZE 200M,
GROUP 2 ('C:\app\Oracle\oradata\ORA12CEXT\redo02A.log','E:\app\Oracle\ORA12CEXT\oradata\redo02B.log','B:\Oracle\oradata\ORA12CEXT\redo02C.log') SIZE 200M,
GROUP 3 ('C:\app\Oracle\oradata\ORA12CEXT\redo03A.log','E:\app\Oracle\ORA12CEXT\oradata\redo03B.log','B:\Oracle\oradata\ORA12CEXT\redo03C.log') SIZE 200M RESETLOGS;
exec dbms_backup_restore.zerodbid(0);
shutdown immediate;
startup nomount pfile="C:\app\Oracle\admin\ORA12CEXT\scripts\initORA12CEXTTemp.ora";
Create controlfile reuse set database "ORA12CEX"
MAXINSTANCES 8
MAXLOGHISTORY 1
MAXLOGFILES 16
MAXLOGMEMBERS 3
MAXDATAFILES 100
Datafile 
'&&file0',
'&&file1',
'&&file2',
'&&file3'
LOGFILE GROUP 1 ('C:\app\Oracle\oradata\ORA12CEXT\redo01A.log','E:\app\Oracle\ORA12CEXT\oradata\redo01B.log','B:\Oracle\oradata\ORA12CEXT\redo01C.log') SIZE 200M,
GROUP 2 ('C:\app\Oracle\oradata\ORA12CEXT\redo02A.log','E:\app\Oracle\ORA12CEXT\oradata\redo02B.log','B:\Oracle\oradata\ORA12CEXT\redo02C.log') SIZE 200M,
GROUP 3 ('C:\app\Oracle\oradata\ORA12CEXT\redo03A.log','E:\app\Oracle\ORA12CEXT\oradata\redo03B.log','B:\Oracle\oradata\ORA12CEXT\redo03C.log') SIZE 200M RESETLOGS;
alter system enable restricted session;
alter database "ORA12CEX" open resetlogs;
DECLARE 
cursor cur_services is 
select name from dba_services where name like 'seeddata%'; 
BEGIN 
 for i in cur_services loop 
 dbms_service.delete_service(i.name); 
 end loop; 
END; 
/
alter database rename global_name to "ORA12CEX.eddyfindt.com";
ALTER TABLESPACE TEMP ADD TEMPFILE 'E:\app\Oracle\DB_UNIQUE_NAME\oradata\TEMP01.DBF' SIZE 20480K REUSE AUTOEXTEND ON NEXT 640K MAXSIZE UNLIMITED;
var dblink NUMBER;
BEGIN SELECT COUNT(*) INTO :DBLINK FROM v$dblink WHERE DB_LINK='DBMS_CLRDBLINK'; IF :DBLINKS > 0 THEN EXECUTE IMMEDIATE 'DROP PUBLIC DATABASE LINK DBMS_CLRDBLINK'; END IF; END;
/
select tablespace_name from dba_tablespaces where tablespace_name='USERS';
ALTER PROFILE default LIMIT PASSWORD_VERIFY_FUNCTION null;
alter user sys account unlock identified by "&&sysPassword";
connect "SYS"/"&&sysPassword" as SYSDBA
alter user system account unlock identified by "&&systemPassword";
select sid, program, serial#, username from v$session;
alter database character set INTERNAL_CONVERT AL32UTF8;
alter database national character set INTERNAL_CONVERT AL16UTF16;
alter system disable restricted session;

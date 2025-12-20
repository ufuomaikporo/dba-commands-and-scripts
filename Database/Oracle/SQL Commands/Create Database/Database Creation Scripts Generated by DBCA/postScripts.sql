SET VERIFY OFF
connect "SYS"/"&&sysPassword" as SYSDBA
set echo on
spool C:\app\Oracle\admin\ORA12CEXT\scripts\postScripts.log append
UPDATE sys.USER$ set SPARE6=NULL;
@C:\app\Oracle\product\12.2.0\dbhome_1\rdbms\admin\dbmssml.sql;
@C:\app\Oracle\product\12.2.0\dbhome_1\rdbms\admin\dbmsclr.plb;
execute dbms_datapump_utl.create_default_dir;
commit;
connect "SYS"/"&&sysPassword" as SYSDBA
alter session set current_schema=ORDSYS;
@C:\app\Oracle\product\12.2.0\dbhome_1\ord\im\admin\ordlib.sql;
alter session set current_schema=SYS;
connect "SYS"/"&&sysPassword" as SYSDBA
create or replace directory XMLDIR as 'C:\app\Oracle\product\12.2.0\dbhome_1\rdbms\xml';
create or replace directory XSDDIR as 'C:\app\Oracle\product\12.2.0\dbhome_1\rdbms\xml\schema';
create or replace directory ORA_DBMS_FCP_ADMINDIR as 'C:\app\Oracle\product\12.2.0\dbhome_1\rdbms\admin';
create or replace directory ORA_DBMS_FCP_LOGDIR as 'C:\app\Oracle\product\12.2.0\dbhome_1\cfgtoollogs';
connect "SYS"/"&&sysPassword" as SYSDBA
connect "SYS"/"&&sysPassword" as SYSDBA
@C:\app\Oracle\product\12.2.0\dbhome_1\rdbms\admin\execocm.sql;
execute dbms_qopatch.replace_logscrpt_dirs;
@C:\app\Oracle\product\12.2.0\dbhome_1\rdbms\admin\execemx.sql;
connect "SYS"/"&&sysPassword" as SYSDBA
set echo on
spool C:\app\Oracle\admin\ORA12CEXT\scripts\postDBCreation.log append
create or replace directory ORACLE_HOME as 'C:\app\Oracle\product\12.2.0\dbhome_1';
create or replace directory ORACLE_BASE as 'C:\app\Oracle';
grant sysdg to sysdg;
grant sysbackup to sysbackup;
grant syskm to syskm;

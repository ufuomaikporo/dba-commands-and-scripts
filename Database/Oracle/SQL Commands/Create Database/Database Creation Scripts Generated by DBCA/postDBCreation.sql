SET VERIFY OFF
spool C:\app\Oracle\admin\ORA12CEXT\scripts\postDBCreation.log append
host C:\app\Oracle\product\12.2.0\dbhome_1\OPatch\datapatch.bat -skip_upgrade_check -db ORA12CEXT;
connect "SYS"/"&&sysPassword" as SYSDBA
set echo on
--create spfile='C:\app\Oracle\product\12.2.0\dbhome_1\database\spfileORA12CEXT.ora' FROM pfile='C:\app\Oracle\admin\ORA12CEXT\scripts\init.ora';
connect "SYS"/"&&sysPassword" as SYSDBA
select 'utlrp_begin: ' || to_char(sysdate, 'HH:MI:SS') from dual;
@C:\app\Oracle\product\12.2.0\dbhome_1\rdbms\admin\utlrp.sql;
select 'utlrp_end: ' || to_char(sysdate, 'HH:MI:SS') from dual;
select comp_id, status from dba_registry;
execute dbms_swrf_internal.cleanup_database(cleanup_local => FALSE);
commit;
shutdown immediate;
connect "SYS"/"&&sysPassword" as SYSDBA
startup ;
spool off
exit;

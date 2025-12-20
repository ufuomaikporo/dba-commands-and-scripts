set verify off
ACCEPT sysPassword CHAR PROMPT 'Enter new password for SYS: ' HIDE
ACCEPT systemPassword CHAR PROMPT 'Enter new password for SYSTEM: ' HIDE
host C:\app\Oracle\product\12.2.0\dbhome_1\bin\orapwd.exe file=C:\app\Oracle\product\12.2.0\dbhome_1\database\PWDORA12CEXT.ora force=y format=12
@C:\app\Oracle\admin\ORA12CEXT\scripts\CloneRmanRestore.sql
@C:\app\Oracle\admin\ORA12CEXT\scripts\cloneDBCreation.sql
@C:\app\Oracle\admin\ORA12CEXT\scripts\postScripts.sql
@C:\app\Oracle\admin\ORA12CEXT\scripts\lockAccount.sql
@C:\app\Oracle\admin\ORA12CEXT\scripts\postDBCreation.sql

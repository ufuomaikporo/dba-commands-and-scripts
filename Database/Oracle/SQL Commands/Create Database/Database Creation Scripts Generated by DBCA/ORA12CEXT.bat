mkdir B:\Oracle\oradata\ORA12CEXT
if %ERRORLEVEL% == 0 ( C:\app\Oracle\product\12.2.0\dbhome_1\bin\oradim.exe -ACL -setperm diag -USER NT AUTHORITY\SYSTEM -OBJTYPE dir -OBJPATH B:\Oracle\oradata\ORA12CEXT -RECURSE false ) 
mkdir C:\app\Oracle
if %ERRORLEVEL% == 0 ( C:\app\Oracle\product\12.2.0\dbhome_1\bin\oradim.exe -ACL -setperm diag -USER NT AUTHORITY\SYSTEM -OBJTYPE dir -OBJPATH C:\app\Oracle -RECURSE false ) 
mkdir C:\app\Oracle\admin\ORA12CEXT\adump
if %ERRORLEVEL% == 0 ( C:\app\Oracle\product\12.2.0\dbhome_1\bin\oradim.exe -ACL -setperm diag -USER NT AUTHORITY\SYSTEM -OBJTYPE dir -OBJPATH C:\app\Oracle\admin\ORA12CEXT\adump -RECURSE false ) 
mkdir C:\app\Oracle\admin\ORA12CEXT\dpdump
if %ERRORLEVEL% == 0 ( C:\app\Oracle\product\12.2.0\dbhome_1\bin\oradim.exe -ACL -setperm diag -USER NT AUTHORITY\SYSTEM -OBJTYPE dir -OBJPATH C:\app\Oracle\admin\ORA12CEXT\dpdump -RECURSE false ) 
mkdir C:\app\Oracle\admin\ORA12CEXT\pfile
if %ERRORLEVEL% == 0 ( C:\app\Oracle\product\12.2.0\dbhome_1\bin\oradim.exe -ACL -setperm diag -USER NT AUTHORITY\SYSTEM -OBJTYPE dir -OBJPATH C:\app\Oracle\admin\ORA12CEXT\pfile -RECURSE false ) 
mkdir C:\app\Oracle\audit
if %ERRORLEVEL% == 0 ( C:\app\Oracle\product\12.2.0\dbhome_1\bin\oradim.exe -ACL -setperm diag -USER NT AUTHORITY\SYSTEM -OBJTYPE dir -OBJPATH C:\app\Oracle\audit -RECURSE false ) 
mkdir C:\app\Oracle\cfgtoollogs\dbca\ORA12CEXT
if %ERRORLEVEL% == 0 ( C:\app\Oracle\product\12.2.0\dbhome_1\bin\oradim.exe -ACL -setperm diag -USER NT AUTHORITY\SYSTEM -OBJTYPE dir -OBJPATH C:\app\Oracle\cfgtoollogs\dbca\ORA12CEXT -RECURSE false ) 
mkdir C:\app\Oracle\oradata\ORA12CEXT
if %ERRORLEVEL% == 0 ( C:\app\Oracle\product\12.2.0\dbhome_1\bin\oradim.exe -ACL -setperm diag -USER NT AUTHORITY\SYSTEM -OBJTYPE dir -OBJPATH C:\app\Oracle\oradata\ORA12CEXT -RECURSE false ) 
mkdir C:\app\Oracle\product\12.2.0\dbhome_1\database
if %ERRORLEVEL% == 0 ( C:\app\Oracle\product\12.2.0\dbhome_1\bin\oradim.exe -ACL -setperm diag -USER NT AUTHORITY\SYSTEM -OBJTYPE dir -OBJPATH C:\app\Oracle\product\12.2.0\dbhome_1\database -RECURSE false ) 
mkdir E:\app\Oracle\DB_UNIQUE_NAME\oradata
if %ERRORLEVEL% == 0 ( C:\app\Oracle\product\12.2.0\dbhome_1\bin\oradim.exe -ACL -setperm diag -USER NT AUTHORITY\SYSTEM -OBJTYPE dir -OBJPATH E:\app\Oracle\DB_UNIQUE_NAME\oradata -RECURSE false ) 
mkdir E:\app\Oracle\ORA12CEXT\oradata
if %ERRORLEVEL% == 0 ( C:\app\Oracle\product\12.2.0\dbhome_1\bin\oradim.exe -ACL -setperm diag -USER NT AUTHORITY\SYSTEM -OBJTYPE dir -OBJPATH E:\app\Oracle\ORA12CEXT\oradata -RECURSE false ) 
set PERL5LIB=%ORACLE_HOME%/rdbms/admin;%PERL5LIB%
set ORACLE_SID=ORA12CEXT
set PATH=%ORACLE_HOME%\bin;%ORACLE_HOME%\perl\bin;%PATH%
C:\app\Oracle\product\12.2.0\dbhome_1\bin\oradim.exe -new -sid ORA12CEXT -startmode manual -spfile 
C:\app\Oracle\product\12.2.0\dbhome_1\bin\oradim.exe -edit -sid ORA12CEXT -startmode auto -srvcstart system 
C:\app\Oracle\product\12.2.0\dbhome_1\bin\sqlplus /nolog @C:\app\Oracle\admin\ORA12CEXT\scripts\ORA12CEXT.sql

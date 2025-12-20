connect target sys/&1;
 
CATALOG START WITH   'C:\app\Oracle\product\12.2.0\dbhome_1\assistants\dbca\templates\\Seed_Database.dfb'  NOPROMPT  ;

RUN {  

set newname for datafile 1 to  'E:\app\Oracle\DB_UNIQUE_NAME\oradata\SYSTEM01.DBF' ; 

set newname for datafile 3 to  'E:\app\Oracle\DB_UNIQUE_NAME\oradata\SYSAUX01.DBF' ; 

set newname for datafile 5 to  'E:\app\Oracle\DB_UNIQUE_NAME\oradata\UNDOTBS01.DBF' ; 

set newname for datafile 7 to  'E:\app\Oracle\DB_UNIQUE_NAME\oradata\USERS01.DBF' ; 

restore datafile 1; 

restore datafile 3; 

restore datafile 5; 

restore datafile 7; }

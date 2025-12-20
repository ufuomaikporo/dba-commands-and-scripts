SET ECHO ON
SPOOL C:\app\Oracle\admin\COCDB\Reports\UfuomaIkporo_EXAM_Q8.out
-- A6387649
set time off

set linesize 100
set pagesize 300

/* ***************************************************************
Place all requested information between the two lines of dashes.
Do not change any information above the top line of dashes
or below the second line of dashes.

Removing or modifying any code above the top line of dashes
or below the second line of dashes will result in loss of marks
or a zero mark on the lab quiz.
**************************************************************** */

----------------------------------------------------------------------------------------------------------------------------

conn sys/oracle@orclpdb as sysdba

SET LIN 120
SET PAGESIZE 100
COLUMN directory_name FORMAT A20
COLUMN directory_path FORMAT A50
COLUMN owner FORMAT A15

SELECT owner, directory_name, directory_path
FROM dba_directories
WHERE directory_name LIKE '%ORCLPDB%';

-- export SCOTT schema

$expdp system/oracle@orclpdb DIRECTORY=ORCLPDB_DIR DUMPFILE=ScottSchemaexport.dmp LOGFILE=ScottSchemaexport.log SCHEMAS=scott

-- import into BOB schema

$impdp system/oracle@orclpdb DIRECTORY=ORCLPDB_DIR DUMPFILE=Scottschemaexport.dmp LOGFILE=BobTableimport.log REMAP_SCHEMA=scott:bob

----------------------------------------------------------------------------------------------------------------------------


SPOOL OFF

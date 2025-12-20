SET ECHO ON
SPOOL C:\app\Oracle\admin\COCDB\Reports\UfuomaIkporo-EXAM-Q4.out
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

REM-------------------------Database name and instance name ----------------------

SELECT name, open_mode, created, log_mode  FROM v$database;

SELECT instance_name FROM v$instance;

REM ----------------------Location of database files------------------------------

SELECT name FROM v$controlfile
UNION
SELECT name FROM gv$datafile
UNION
SELECT member FROM v$logfile
UNION
SELECT name FROM gv$tempfile
ORDER BY 1;

REM---------------------------Database Service names--------------------------------

SELECT name FROM v$services;

REM --------------------------Oracle components that were installed------------------

COLUMN comp_name FORMAT A50
COLUMN status FORMAT A20

SELECT comp_name, status FROM dba_registry;

SHOW CON_NAME

ALTER SESSION SET CONTAINER=PDB$SEED;

COLUMN comp_name FORMAT A50
COLUMN status FORMAT A20

SELECT comp_name, status FROM dba_registry;

SHOW CON_NAME


----------------------------------------------------------------------------------------------------------------------------


SPOOL OFF

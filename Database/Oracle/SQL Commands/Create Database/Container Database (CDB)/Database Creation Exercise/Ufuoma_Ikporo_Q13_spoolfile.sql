SET ECHO ON
SPOOL C:\app\Oracle\admin\COCDB\Reports\UfuomaIkporo_EXAM_Q13.out
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

-- tables

DESC prod
DESC well
DESC zcode
DESC pcode

-- TABLE CONSTRAINTS

SET LIN 200
SET PAGESIZE 100
COLUMN constraint_name FORMAT A30
COLUMN table_name FORMAT A25
COLUMN column_name FORMAT A20
COLUMN constraint_type FORMAT A15
BREAK ON table_name

SELECT uc.table_name, 
       uc.constraint_name, 
       uc.constraint_type,
       ucc.column_name,
       uc.status
FROM user_cons_columns ucc, user_constraints uc
WHERE ucc.constraint_name = uc.constraint_name
AND ucc.OWNER = 'ACCT_ADMIN'
ORDER BY uc.table_name;

-- iNDEXES

SET LIN 200
COL index_name FORMAT A20
COL table_owner FORMAT A10
COL table_name FORMAT A15
COL tablespace_name FORMAT A15

SELECT index_name, 
       index_type, 
       table_name,
       table_type,
       table_owner,
       tablespace_name,
       uniqueness
FROM dba_indexes
WHERE table_owner = 'ACCT_ADMIN'
ORDER BY 1;

-- SYNONYMS

COL synonym_name FORMAT A20
COL table_name FORMAT A20
COL table_owner FORMAT A20

SELECT synonym_name, table_name, table_owner
FROM dba_synonyms
WHERE table_owner = 'ACCT_ADMIN';

-- TABLES

SET LIN 200
COL owner FORMAT A15
COL table_name FORMAT A15
COL tablespace_name FORMAT A20
COL temporary FORMAT A10

SELECT table_name, 
       tablespace_name,
       owner, 
       status, 
       temporary,
       initial_extent
FROM dba_tables
WHERE owner = 'ACCT_ADMIN'
ORDER BY 1;

----------------------------------------------------------------------------------------------------------------------------


SPOOL OFF

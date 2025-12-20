SET ECHO ON
SPOOL C:\app\Oracle\admin\COCDB\Reports\UfuomaIkporo_EXAM_Q12.out
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

conn acct_admin/Or5cle#123@acctpdb

CREATE USER landmgr IDENTIFIED BY landmgr#123
DEFAULT TABLESPACE users
TEMPORARY TABLESPACE temp
QUOTA 10M ON users;

CREATE USER landadmin IDENTIFIED BY landadmin#123
DEFAULT TABLESPACE users
TEMPORARY TABLESPACE temp
QUOTA 100M ON users;

GRANT CREATE SESSION TO landmgr;

GRANT CREATE SESSION TO landadmin;

CREATE ROLE manager;

CREATE ROLE entry;

GRANT SELECT, INSERT, UPDATE, DELETE ON prod
TO manager;

GRANT SELECT, INSERT, UPDATE, DELETE ON well
TO manager;

GRANT SELECT, INSERT, UPDATE, DELETE ON zcode
TO manager;

GRANT SELECT, INSERT, UPDATE, DELETE ON pcode
TO manager;

GRANT SELECT, INSERT, UPDATE on prod 
TO entry;

GRANT SELECT, INSERT, UPDATE on well 
TO entry;

GRANT SELECT, INSERT, UPDATE on zcode
TO entry;

GRANT SELECT, INSERT, UPDATE on pcode
TO entry;

-- enable profile and resource managagement

conn / as sysdba

@?\rdbms\admin\utlpwdmg.sql

ALTER SYSTEM SET RESOURCE_LIMIT=TRUE;

conn acct_admin/Or5cle#123@acctpdb

DROP PROFILE prod_mgr CASCADE;

DROP PROFILE prod_admin CASCADE;

CREATE PROFILE prod_mgr LIMIT
FAILED_LOGIN_ATTEMPTS    3
PASSWORD_LIFE_TIME       60
PASSWORD_REUSE_TIME      365
PASSWORD_VERIFY_FUNCTION ora12c_verify_function
PASSWORD_GRACE_TIME       5
IDLE_TIME                 30;

CREATE PROFILE prod_admin LIMIT
FAILED_LOGIN_ATTEMPTS    3
PASSWORD_LIFE_TIME       90
PASSWORD_REUSE_TIME      365
PASSWORD_VERIFY_FUNCTION ora12c_verify_function
PASSWORD_GRACE_TIME       5
SESSIONS_PER_USER         1
IDLE_TIME                 20;

GRANT manager TO landmgr;

GRANT entry TO landadmin;

ALTER USER landmgr PROFILE prod_mgr;

ALTER USER landadmin PROFILE prod_admin;

----------------------------------------------------------------------------------------------------------------------------


SPOOL OFF

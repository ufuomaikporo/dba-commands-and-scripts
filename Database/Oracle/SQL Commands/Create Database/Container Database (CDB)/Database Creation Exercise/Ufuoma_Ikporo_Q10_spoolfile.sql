SET ECHO ON
SPOOL C:\app\Oracle\admin\COCDB\Reports\UfuomaIkporo_EXAM_Q10.out
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

-- Load Production Table

TRUNCATE TABLE production;

$SQLLDR USERID=acct_admin/Or5cle#123@acctpdb CONTROL=C:\DBA\Exam\Load_data\Load_prod_oil_data.ctl LOG=C:\DBA\Exam\Load_data\Load_prod_oil_data.log
$SQLLDR USERID=acct_admin/Or5cle#123@acctpdb CONTROL=C:\DBA\Exam\Load_data\Load_prod_gas_data.ctl LOG=C:\DBA\Exam\Load_data\Load_prod_gas_data.log
$SQLLDR USERID=acct_admin/Or5cle#123@acctpdb CONTROL=C:\DBA\Exam\Load_data\Load_prod_water_data.ctl LOG=C:\DBA\Exam\Load_data\Load_prod_water_data.log
$SQLLDR USERID=acct_admin/Or5cle#123@acctpdb CONTROL=C:\DBA\Exam\Load_data\Load_prod_cond_data.ctl LOG=C:\DBA\Exam\Load_data\Load_prod_cond_data.log

$SQLLDR USERID=acct_admin/Or5cle#123@acctpdb CONTROL=C:\DBA\Exam\Load_data\Load_well_info_data.ctl LOG=C:\DBA\Exam\Load_data\Load_well_info_data.log

$SQLLDR USERID=acct_admin/Or5cle#123@acctpdb CONTROL=C:\DBA\Exam\Load_data\Load_zone_code_data.ctl LOG=C:\DBA\Exam\Load_data\Load_zone_code_data.log

-- Insert into prod_code Table

TRUNCATE TABLE prod_code;

INSERT INTO prod_code
VALUES (1, 'OIL');

INSERT INTO prod_code
VALUES (2, 'GAS');

INSERT INTO prod_code
VALUES (3, 'WATER');

INSERT INTO prod_code
VALUES (4, 'CONDENSATE');

COMMIT;

-- verify tables are loaded

SELECT COUNT(*) FROM production;

SELECT COUNT(*) FROM well_info;

SELECT COUNT(*) FROM prod_code;

SELECT COUNT(*) FROM zone_code;

-- View disabled constraints

COL table_name FORMAT A20
COL constraint_name FORMAT A35
COL search_condition FORMAT A30
COL owner FORMAT A20
SET LIN 120
SET PAGESIZE 300

SELECT table_name, 
       owner,
       constraint_name, 
       constraint_type,
       status,
       search_condition
FROM dba_constraints
WHERE owner = 'ACCT_ADMIN'
AND status = 'DISABLED'
ORDER BY 1, 3;

-- enable constraints

ALTER TABLE production 
ENABLE CONSTRAINT production_well_info_fk;

ALTER TABLE production 
ENABLE CONSTRAINT production_prod_code_fk;

ALTER TABLE production 
ENABLE CONSTRAINT production_zone_code_fk;

-- SHOW Disabled Constraints

SELECT table_name, 
       owner,
       constraint_name, 
       constraint_type,
       status,
       search_condition
FROM dba_constraints
WHERE owner = 'ACCT_ADMIN'
AND status = 'DISABLED'
ORDER BY 1, 3;

-- Show alll constraints

SELECT table_name, 
       owner,
       constraint_name, 
       constraint_type,
       status,
       search_condition
FROM dba_constraints
WHERE owner = 'ACCT_ADMIN'
ORDER BY 1, 3;

----------------------------------------------------------------------------------------------------------------------------


SPOOL OFF

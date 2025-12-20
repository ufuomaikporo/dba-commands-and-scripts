SET ECHO ON
SPOOL C:\app\Oracle\admin\COCDB\Reports\UfuomaIkporo_EXAM_Q11.out
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

DROP PUBLIC SYNONYM pcode;
DROP PUBLIC SYNONYM zcode;
DROP PUBLIC SYNONYM prod;
DROP PUBLIC SYNONYM well;

CREATE PUBLIC SYNONYM prod FOR acct_admin.production;

CREATE PUBLIC SYNONYM well FOR acct_admin.well_info;

CREATE PUBLIC SYNONYM pcode FOR acct_admin.prod_code;

CREATE PUBLIC SYNONYM zcode FOR acct_admin.zone_code;

-- Check that public synonyms work

conn system/Or5cle#123

SELECT COUNT(*) FROM zcode;


SELECT COUNT(*) FROM pcode;


SELECT COUNT(*) FROM prod;


SELECT COUNT(*) FROM well;



----------------------------------------------------------------------------------------------------------------------------


SPOOL OFF

SET ECHO ON
SPOOL C:\app\Oracle\admin\COCDB\Reports\UfuomaIkporo_EXAM_Q9.out
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

-- Drop and Create tables

DROP TABLE production CASCADE CONSTRAINTS;
DROP TABLE well_info CASCADE CONSTRAINTS;
DROP TABLE prod_code CASCADE CONSTRAINTS;
DROP TABLE zone_code CASCADE CONSTRAINTS;

CREATE TABLE well_info
(uwi           VARCHAR2(16) CONSTRAINT well_info_uwi_pk PRIMARY KEY 
       USING INDEX STORAGE (INITIAL 100K NEXT 100K PCTINCREASE 20) TABLESPACE INDX,
 field_agent   VARCHAR2(20) CONSTRAINT well_info_field_agent_nn NOT NULL,
 le            NUMBER(3) CONSTRAINT well_info_le_nn NOT NULL,
 lsd           NUMBER(2) CONSTRAINT well_info_lsd_nn NOT NULL,
 sec           NUMBER(2) CONSTRAINT well_info_sec_nn NOT NULL,
 twp           NUMBER(3) CONSTRAINT well_info_twp_nn NOT NULL,
 rge           NUMBER(2) CONSTRAINT well_info_rge_nn NOT NULL,
 mer           VARCHAR2(2) CONSTRAINT well_info_mer_nn NOT NULL,
 es            NUMBER(1) CONSTRAINT well_info_es_nn NOT NULL
 ) TABLESPACE users;

CREATE TABLE prod_code
(prod_type  NUMBER(1) CONSTRAINT prod_code_pk PRIMARY KEY 
       USING INDEX STORAGE (INITIAL 100K NEXT 100K PCTINCREASE 20) TABLESPACE INDX, 
 prod_description VARCHAR2(20) CONSTRAINT prod_code_description_nn NOT NULL
) TABLESPACE users;

CREATE TABLE zone_code
(zone_id VARCHAR2(6) CONSTRAINT zone_code_pk PRIMARY KEY 
       USING INDEX STORAGE (INITIAL 100K NEXT 100K PCTINCREASE 20) TABLESPACE INDX,
 zone_description VARCHAR2(25) CONSTRAINT zone_code_description_nn NOT NULL
) TABLESPACE users;

CREATE TABLE production
(uwi       VARCHAR2(16),
 prod_date DATE,
 zone_id   VARCHAR2(6),
 prod_type NUMBER(1),
 prod_amt  NUMBER(6,2) CONSTRAINT production_prod_amt_nn NOT NULL,
 hours     NUMBER(3) CONSTRAINT production_hours_nn NOT NULL,
 CONSTRAINT production_comp_pk PRIMARY KEY (uwi, prod_date, zone_id, prod_type)
       USING INDEX STORAGE (INITIAL 100K NEXT 100K PCTINCREASE 20) TABLESPACE INDX,
 CONSTRAINT production_well_info_fk FOREIGN KEY (uwi)
       REFERENCES well_info (uwi) DEFERRABLE DISABLE,
 CONSTRAINT production_prod_code_fk FOREIGN KEY (prod_type)
       REFERENCES prod_code(prod_type) DEFERRABLE DISABLE,
 CONSTRAINT production_zone_code_fk FOREIGN KEY (zone_id)
       REFERENCES zone_code(zone_id) DEFERRABLE DISABLE 
) TABLESPACE users;

-- Verify creation of tables

COL tname FORMAT A20

SELECT tname FROM tab

-- Constraints on tables

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
ORDER BY 1, 3;

----------------------------------------------------------------------------------------------------------------------------


SPOOL OFF

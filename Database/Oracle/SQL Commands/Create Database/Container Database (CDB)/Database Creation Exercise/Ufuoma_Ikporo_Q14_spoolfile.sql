SET ECHO ON
SPOOL C:\app\Oracle\admin\COCDB\Reports\UfuomaIkporo_EXAM_Q14.out
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

CREATE OR REPLACE VIEW total_oil
AS (SELECT uwi, sum(prod_amt) as total_oil_prod
    FROM prod 
    JOIN well USING (uwi)
    WHERE prod_type = 1
    AND le = 100
    GROUP BY uwi
);

CREATE OR REPLACE VIEW total_gas
AS (SELECT uwi, sum(prod_amt) as total_gas_prod
    FROM prod 
    JOIN well USING (uwi)
    WHERE prod_type = 2
    AND le = 100
    GROUP BY uwi
);

CREATE OR REPLACE VIEW total_water
AS (SELECT uwi, sum(prod_amt) as total_water_prod
    FROM prod 
    JOIN well USING (uwi)
    WHERE prod_type = 3
    AND le = 100
    GROUP BY uwi
);

CREATE OR REPLACE VIEW total_cond
AS (SELECT uwi, sum(prod_amt) as total_cond_prod
    FROM prod 
    JOIN well_info USING (uwi)
    WHERE prod_type = 4
    AND le = 100
    GROUP BY uwi
);

SELECT uwi,total_oil_prod, total_gas_prod, total_water_prod, total_cond_prod
FROM total_oil
JOIN total_gas USING (uwi)
JOIN total_water USING (uwi)
JOIN total_cond USING (uwi);

REM--------------------------------PART 2

SELECT COUNT(*) 
FROM prod
JOIN zcode USING (zone_id)
WHERE prod_type IN (1,2)
AND zone_description = 'MANVILLE';

REM---------------------------------PART 3

SELECT ((SUM(prod_amt)/COUNT(*))*35.314724)/(SUM(hours)/24)
FROM prod
JOIN well USING (uwi)
WHERE le = 102
AND prod_type = 2;

REM------------------------------PART 4

SELECT uwi, prod_amt
FROM prod
JOIN well USING (uwi)
WHERE prod_type = 2 AND
le = (SELECT le
FROM prod
JOIN well USING (uwi)
WHERE prod_type = 2
AND prod_amt >= 
(SELECT MAX(MAX(prod_amt))
FROM prod p
JOIN pcode pc USING (prod_type)
JOIN well w USING (uwi)
WHERE prod_description = 'GAS'
GROUP BY w.le ));

REM----------------------PART 5

CREATE OR REPLACE VIEW total_oil_prod_per_lease
AS (SELECT w.le AS lease, prod_description, SUM(prod_amt) AS oil_prod_amt
   FROM prod
JOIN pcode USING (prod_type)
JOIN well w USING (uwi)
WHERE prod_description = 'OIL'
GROUP BY w.le, prod_description);

CREATE OR REPLACE VIEW total_gas_prod_per_lease
AS (SELECT w.le AS lease, prod_description, SUM(prod_amt) AS gas_prod_amt
   FROM prod
JOIN pcode USING (prod_type)
JOIN well w USING (uwi)
WHERE prod_description = 'GAS'
GROUP BY w.le, prod_description);

SELECT lease, 
       oil_prod_amt, 
       gas_prod_amt, 
       oil_prod_amt + gas_prod_amt AS total_production
FROM total_oil_prod_per_lease
JOIN total_gas_prod_per_lease
USING (lease);

----------------------------------------------------------------------------------------------------------------------------


SPOOL OFF

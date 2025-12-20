OPTIONS(skip=1, direct=false, errors=2000)

LOAD DATA
INFILE 'C:\DBA\Exam\Load_data\Examdata2021.csv'
BADFILE 'C:\DBA\Exam\Load_data\Load_well_info_data.bad'
DISCARDFILE 'C:\TXPDB\C_Drive\scripts\Loading_tables\payment\Load_well_info_data.dsc'

REPLACE INTO TABLE well_info
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS  
(uwi         CHAR,
 zone_id     FILLER,
 prod_date   FILLER,
 oil_m3      FILLER,
 oil_bbl     FILLER,
 gas_e3_m3   FILLER,
 gas_mcf     FILLER,
 prod_amt    FILLER,
 water_bbl   FILLER,
 cond_m3     FILLER,
 cond_bbl    FILLER,
 hours       FILLER,
 le          INTEGER EXTERNAL,
 lsd         INTEGER EXTERNAL,
 sec         INTEGER EXTERNAL,
 twp         INTEGER EXTERNAL,
 rge         INTEGER EXTERNAL,
 mer         CHAR,
 es          INTEGER EXTERNAL,
 field_agent CONSTANT 'James'
 )
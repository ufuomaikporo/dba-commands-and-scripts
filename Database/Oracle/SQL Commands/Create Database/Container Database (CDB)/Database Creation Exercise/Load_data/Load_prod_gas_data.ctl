OPTIONS(skip=1, direct=false, errors=2000)

LOAD DATA
INFILE 'C:\DBA\Exam\Load_data\Examdata2021.csv'
BADFILE 'C:\DBA\Exam\Load_data\Load_prod_gas_data.bad'
DISCARDFILE 'C:\TXPDB\C_Drive\scripts\Loading_tables\payment\Load_prod_gas_data.dsc'

APPEND INTO TABLE production
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS  
(uwi       CHAR,
 zone_id   CHAR,
 prod_date DATE "MON-YY",
 oil_m3    FILLER,
 oil_bbl   FILLER,
 prod_amt  DECIMAL EXTERNAL,
 gas_mcf   FILLER,
 water_m3  FILLER,
 water_bbl FILLER,
 cond_m3   FILLER,
 cond_bbl  FILLER,
 hours     INTEGER EXTERNAL,
 le        FILLER,
 lsd       FILLER,
 sec       FILLER,
 twp       FILLER,
 rge       FILLER,
 mer       FILLER,
 es        FILLER,
 prod_type CONSTANT '2'
 )
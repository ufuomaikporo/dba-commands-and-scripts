OPTIONS(skip=1, direct=false, errors=2000)

LOAD DATA
INFILE 'C:\DBA\Exam\Load_data\Examdata2021_ZoneID.csv'
BADFILE 'C:\DBA\Exam\Load_data\Load_zone_code_data.bad'
DISCARDFILE 'C:\TXPDB\C_Drive\scripts\Loading_tables\payment\Load_zone_code_data.dsc'

REPLACE INTO TABLE zone_code
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS  
(zone_id          CHAR,
 zone_description CHAR
 )
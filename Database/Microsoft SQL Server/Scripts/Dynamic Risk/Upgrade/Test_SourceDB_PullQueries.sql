
USE ETP_IRASv6_CONFIG_TEST
USE ETP_IRASv6_TEST_CONFIG
SELECT DISTINCT 'EXECUTE IMMEDIATE ( ''SELECT COUNT(*) FROM (' + REPLACE(sqlstatement, '''', '''''') + ')'');'  FROM DETableMapping where DataSource = 'UPDM'
AND sqlstatement is not null order by 1

select DISTINCT DataSource from [DataExchangeAllMappingsInfo]

SELECT DISTINCT 'sql_stmt := ''SELECT ''''' + TableName + ''''' FROM (' + REPLACE(Mainsqlstatement, '''', '''''') + ') WHERE 1 = 0'';' + CHAR(10) + 'EXECUTE IMMEDIATE sql_stmt;' 
FROM [DataExchangeAllMappingsInfo] 
WHERE Mainsqlstatement is not null 
AND  ProjectName = '01 - QRA_Main_2024/02' and Mainsqlstatement NOT LIKE '%--%' 
AND DataSource = 'UPDM'

-- From results Query 7

SELECT * FROM DETableMapping WHERE TableName = 'Corporation' AND  ProjectName = '01 - QRA_Main_2024/02'
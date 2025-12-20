SET SERVEROUTPUT ON;
DECLARE 
	sql_stmt VARCHAR2(20000);
	CNT INT;
	
	/*GRANT the same object priviliges for ETP_IRASV6_TEST as was granted to ETP_IRASV6_STAGE
	on objects in ETP_IRASV6_TEST_OWNR schema
	*/
	CURSOR tab_priv_cursor IS 
	SELECT 'GRANT ' || privilege || ' ON ' || REPLACE(owner, 'STAGE', 'TEST') || '."' || table_name 
				|| '" TO ' || REPLACE(grantee, 'STAGE', 'TEST') AS grant_stmt
	FROM dba_tab_privs dtp
	WHERE grantee IN ('ETP_IRASV6_STAGE')
	AND table_name IN (SELECT table_name FROM all_tables WHERE owner = 'ETP_IRASV6_TEST_OWNR');	
BEGIN
	FOR priv IN tab_priv_cursor LOOP
		sql_stmt := priv.grant_stmt;
		EXECUTE IMMEDIATE sql_stmt;
	END LOOP;
	
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE (CHR(10) || sql_stmt);
        DBMS_OUTPUT.PUT_LINE (CHR(10) || SQLERRM);

END;
/
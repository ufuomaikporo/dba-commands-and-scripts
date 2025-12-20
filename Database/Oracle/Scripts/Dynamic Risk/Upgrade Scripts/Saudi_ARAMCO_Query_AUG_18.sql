ALTER SESSION SET nls_comp = Linguistic;
ALTER SESSION SET nls_sort = binary_CI;

DECLARE
    CNT NUMBER;
    globalid RAW(32);

    CURSOR db_cursor IS    
    SELECT P.GLOBALID
    FROM SPIPEU_USER_P_MAINLINE_SEGMENTS P;

BEGIN

    SELECT COUNT(*) INTO CNT
    FROM user_tables
    WHERE table_name = 'vertices_table';

    IF (CNT = 0) THEN
        EXECUTE IMMEDIATE 'CREATE GLOBAL TEMPORARY TABLE vertices_table 
                            (GLOBALID RAW(32) DEFAULT SYS_GUID()
                            ,vertex_index INT
                            ,X_Point NUMBER
                            ,Y_Point NUMBER
                            ,Elevation NUMBER
                            ,Stationnum NUMBER)';
    END IF;

    -- Loop through cursor
    FOR record IN db_cursor LOOP
        DECLARE
            Counter NUMBER;
        BEGIN

            SELECT MLS.shape.STNumPoints() INTO Counter
            FROM SPIPEU_USER_P_MAINLINE_SEGMENTS MLS
            WHERE MLS.GLOBALID = globalid;

            FOR i IN 1..Counter LOOP

                INSERT INTO vertices_table 
                SELECT P.GLOBALID
                        ,@Counter AS vertex_index
                        ,P.shape.STPointN(i).STX AS X_Point
                        ,P.shape.STPointN(i).STY AS Y_Point
                        ,P.shape.STPointN(i).Z as Elevation
                        ,P.shape.STPointN(i).M as Stationnum
                FROM SPIPEU_USER_P_MAINLINE_SEGMENTS P
                WHERE P.GLOBALID = globalid;

            END LOOP; -- End for-loop

        END;
    END LOOP; -- End cursor

    -- Select query

    SELECT  mlseg.YEAR_INSTALLED as EffectiveStartDate,	
			null as EffectiveEndDate,	
			null as BendTypeDomainId,	
			null as BendAngle,	
			null as BendLatitude,	
			null as BendLongitude,	
			'Asia_Lambert_Conformal_Conic - Ain el Abd 1970' as BendCoordSysDomainId,	
			vt.X_Point as BendX,	
			vt.Y_Point as BendY,	
			vt.Elevation as BendZ,	
			null as BendEngineeringStnFlg,	
			TBD as StationSeriesId,	
			vt.StationNum,	
			null as BendName,	
			CONCAT(TBD,'_',ROW_NUMBER() OVER(Partition BY TBD, ID ORDER BY TBD)) as SourceId,	
			TBD as BeginStationSeriesId,	
			vt.StationNum as BeginStationNum,	
			TBD as EndStationSeriesId,
			vt.StationNum as EndStationNum
    FROM vertices_table vt
    JOIN SPIPEU_USER_P_MAINLINE_SEGMENTS mlseg on mlseg.GLOBALID = vt.GLOBALID
    ORDER BY TBD,vt.Stationnum;

    SELECT COUNT(*) INTO CNT
    FROM user_tables
    WHERE table_name = 'vertices_table';

    IF (CNT <> 0) THEN
        EXECUTE IMMEDIATE 'DROP TABLE vertices_table';
    END IF;
END;
/




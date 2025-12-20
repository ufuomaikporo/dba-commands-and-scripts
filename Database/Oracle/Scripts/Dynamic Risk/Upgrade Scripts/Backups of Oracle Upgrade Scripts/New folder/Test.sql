CREATE OR REPLACE PROCEDURE "SP_DX6CONFIGV5" 

        AS
        BEGIN

            BEGIN
            EXECUTE IMMEDIATE 'DROP TABLE temp_Fabrication';
            EXCEPTION
            WHEN OTHERS THEN
                    NULL;
                END;
        DECLARE
            CRF_sql    VARCHAR(20000) :=null;
            INF_sql    VARCHAR(20000) :=null;
        BEGIN 

            CRF_sql  := 'CREATE TABLE temp_Fabrication
            (
                Id                               NUMBER(18, 0) NULL,
                EffectiveStartDate               DATE NULL,
                EffectiveEndDate                 DATE NULL,
                FabricationTypeDomainId          NUMBER(7, 0) NULL,
                FabricationTypeDomainCode        VARCHAR2(40) NULL,
                FabricationTypeDomainDesc        VARCHAR2(255) NULL,
                FabricationOutsideDiameter       NUMBER(8, 4) NULL,
                FabricationName                  VARCHAR2(100) NULL,
                FabricationComment               VARCHAR2(255) NULL,
                StationSeriesId                  NUMBER(10, 0) NULL,
                StationNum                       NUMBER(10, 3) NULL,
                FabricationManufacturingTypeLd   NUMBER(7, 0) NULL,
                FabricationManufacturingTypeCode VARCHAR2(40) NULL,
                FabricationManufacturingTypeDesc VARCHAR2(255) NULL,
                FabricationOutletGrade           NUMBER(5, 0) NULL,
                FabricationOutletWallthickness   NUMBER(9, 5) NULL,
                FabricationInletDiameter         NUMBER(5, 3) NULL,
                FabricationInletGrade            NUMBER(5, 0) NULL,
                FabricationInletWallThickness    NUMBER(9, 5) NULL,
                FabricationPressureRating        NUMBER(5, 0) NULL,
                FabricationOutletDiameter        NUMBER(5, 3) NULL,
                FabricationConnectDomainID       NUMBER(7, 0) NULL,
                FabricationConnectCode           VARCHAR2(40) NULL,
                FabricationConnectDesc           VARCHAR2(255) NULL
            )';
        
        EXECUTE IMMEDIATE CRF_sql;

        BEGIN

            INF_sql := 'INSERT INTO temp_Fabrication
                        (Id,
                        EffectiveStartDate,
                        EffectiveEndDate,
                        FabricationTypeDomainCode,
                        FabricationTypeDomainDesc,
                        FabricationOutsideDiameter,
                        FabricationName,
                        FabricationComment,
                        StationSeriesId,
                        StationNum,
                        FabricationManufacturingTypeCode,
                        FabricationManufacturingTypeDesc,
                        FabricationOutletGrade,
                        FabricationOutletWallthickness,
                        FabricationInletDiameter,
                        FabricationInletGrade,
                        FabricationInletWallThickness,
                        FabricationPressureRating,
                        FabricationOutletDiameter,
                        FabricationConnectCode,
                        FabricationConnectDesc)
            SELECT Row_number( )
                    OVER (
                    ORDER BY BeginStationSeriesId, BeginStationNum) AS Id,
                EffectiveStartDate,
                EffectiveEndDate,
                ElbowTypeCode,
                ElbowTypeDescr,
                ElbowOutsideDiameter,
                ElbowName,
                ElbowComment,
                BeginStationSeriesId,
                BeginStationNum,
                ElbowManufacturingTypeCode,
                ElbowManufacturingTypeDescr,
                ElbowOutletGrade,
                ElbowOutletWallthickness,
                ElbowInletDiameter,
                ElbowInletGrade,
                ElbowInletWallThickness,
                ElbowPressureRating,
                ElbowOutletDiameter,
                ElbowConnectCode,
                ElbowConnectDescr
            FROM   ( SELECT f.Id,
                            EffectiveStartDate,
                            EffectiveEndDate,
                            t.Code  AS ElbowTypeCode,
                            t.Descr AS ElbowTypeDescr,
                            ElbowOutsideDiameter,
                            ElbowName,
                            ElbowComment,
                            BeginStationSeriesId,
                            BeginStationNum,
                            m.Code  AS ElbowManufacturingTypeCode,
                            m.Descr AS ElbowManufacturingTypeDescr,
                            ElbowOutletGrade,
                            ElbowOutletWallthickness,
                            ElbowInletDiameter,
                            ElbowInletGrade,
                            ElbowInletWallThickness,
                            ElbowPressureRating,
                            ElbowOutletDiameter,
                            c.Code  AS ElbowConnectCode,
                            c.Descr AS ElbowConnectDescr
                    FROM   Elbow f
                            LEFT JOIN ListDomain c
                                ON f.ElbowConnectDomainId = c.Id
                            LEFT JOIN ListDomain m
                                ON f.ElbowManufacturingTypeLd = m.Id
                            LEFT JOIN ListDomain t
                                ON f.ElbowTypeDomainId = t.Id
                    UNION
                    SELECT f.Id,
                            EffectiveStartDate,
                            EffectiveEndDate,
                            t.Code  AS ExtrusionTypeCode,
                            t.Descr AS ExtrusionTypeDescr,
                            ExtrusionOutsideDiameter,
                            ExtrusionName,
                            ExtrusionComment,
                            BeginStationSeriesId,
                            BeginStationNum,
                            m.Code  AS ExtrusionManufacturingTypeCode,
                            m.Descr AS ExtrusionManufacturingTypeDescr,
                            ExtrusionOutletGrade,
                            ExtrusionOutletWallthickness,
                            ExtrusionInletDiameter,
                            ExtrusionInletGrade,
                            ExtrusionInletWallThickness,
                            ExtrusionPressureRating,
                            ExtrusionOutletDiameter,
                            c.Code  AS ExtrusionConnectCode,
                            c.Descr AS ExtrusionConnectDescr
                    FROM   Extrusion f
                            LEFT JOIN ListDomain c
                                ON f.ExtrusionConnectDomainId = c.Id
                            LEFT JOIN ListDomain m
                                ON f.ExtrusionManufacturingTypeLd = m.Id
                            LEFT JOIN ListDomain t
                                ON f.ExtrusionTypeDomainId = t.Id
                    UNION
                    SELECT f.Id,
                            EffectiveStartDate,
                            EffectiveEndDate,
                            t.Code  AS FlangeTypeCode,
                            t.Descr AS FlangeTypeDescr,
                            FlangeOutsideDiameter,
                            FlangeName,
                            FlangeComment,
                            BeginStationSeriesId,
                            BeginStationNum,
                            m.Code  AS FlangeManufacturingTypeCode,
                            m.Descr AS FlangeManufacturingTypeDescr,
                            FlangeOutletGrade,
                            FlangeOutletWallthickness,
                            FlangeInletDiameter,
                            FlangeInletGrade,
                            FlangeInletWallThickness,
                            FlangePressureRating,
                            FlangeOutletDiameter,
                            c.Code  AS FlangeConnectCode,
                            c.Descr AS FlangeConnectDescr
                    FROM   Flange f
                            LEFT JOIN ListDomain c
                                ON f.FlangeConnectDomainId = c.Id
                            LEFT JOIN ListDomain m
                                ON f.FlangeManufacturingTypeLd = m.Id
                            LEFT JOIN ListDomain t
                                ON f.FlangeTypeDomainId = t.Id
                    UNION
                    SELECT f.Id,
                            EffectiveStartDate,
                            EffectiveEndDate,
                            t.Code  AS ReducerTypeCode,
                            t.Descr AS ReducerTypeDescr,
                            ReducerOutsideDiameter,
                            ReducerName,
                            ReducerComment,
                            BeginStationSeriesId,
                            BeginStationNum,
                            m.Code  AS ReducerManufacturingTypeCode,
                            m.Descr AS ReducerManufacturingTypeDescr,
                            ReducerOutletGrade,
                            ReducerOutletWallthickness,
                            ReducerInletDiameter,
                            ReducerInletGrade,
                            ReducerInletWallThickness,
                            ReducerPressureRating,
                            ReducerOutletDiameter,
                            c.Code  AS ReducerConnectCode,
                            c.Descr AS ReducerConnectDescr
                    FROM   Reducer f
                            LEFT JOIN ListDomain c
                                ON f.ReducerConnectDomainId = c.Id
                            LEFT JOIN ListDomain m
                                ON f.ReducerManufacturingTypeLd = m.Id
                            LEFT JOIN ListDomain t
                                ON f.ReducerTypeDomainId = t.Id
                    UNION
                    SELECT f.Id,
                            EffectiveStartDate,
                            EffectiveEndDate,
                            t.Code  AS TeeTypeCode,
                            t.Descr AS TeeTypeDescr,
                            TeeOutsideDiameter,
                            TeeName,
                            TeeComment,
                            BeginStationSeriesId,
                            BeginStationNum,
                            m.Code  AS TeeManufacturingTypeCode,
                            m.Descr AS TeeManufacturingTypeDescr,
                            TeeOutletGrade,
                            TeeOutletWallthickness,
                            TeeInletDiameter,
                            TeeInletGrade,
                            TeeInletWallThickness,
                            TeePressureRating,
                            TeeOutletDiameter,
                            c.Code  AS TeeConnectCode,
                            c.Descr AS TeeConnectDescr
                    FROM   Tee f
                            LEFT JOIN ListDomain c
                                ON f.TeeConnectDomainId = c.Id
                            LEFT JOIN ListDomain m
                                ON f.TeeManufacturingTypeLd = m.Id
                            LEFT JOIN ListDomain t
                                ON f.TeeTypeDomainId = t.Id
                    UNION
                    SELECT f.Id,
                            EffectiveStartDate,
                            EffectiveEndDate,
                            t.Code  AS TeeTypeCode,
                            t.Descr AS TeeTypeDescr,
                            TapOutsideDiameter,
                            TapName,
                            TapComment,
                            BeginStationSeriesId,
                            BeginStationNum,
                            m.Code  AS TapManufacturingTypeCode,
                            m.Descr AS TapManufacturingTypeDescr,
                            TapOutletGrade,
                            TapOutletWallthickness,
                            TapInletDiameter,
                            TapInletGrade,
                            TapInletWallThickness,
                            TapPressureRating,
                            TapOutletDiameter,
                            c.Code  AS TapConnectCode,
                            c.Descr AS TapConnectDescr
                    FROM   Tap f
                            LEFT JOIN ListDomain c
                                ON f.TapConnectDomainId = c.Id
                            LEFT JOIN ListDomain m
                                ON f.TapManufacturingTypeLd = m.Id
                            LEFT JOIN ListDomain t
                                ON f.TapTypeDomainId = t.Id
                    UNION
                    SELECT f.Id,
                            EffectiveStartDate,
                            EffectiveEndDate,
                            t.Code  AS VentTypeCode,
                            t.Descr AS VentTypeDescr,
                            VentOutsideDiameter,
                            VentName,
                            VentComment,
                            BeginStationSeriesId,
                            BeginStationNum,
                            m.Code  AS VentManufacturingTypeCode,
                            m.Descr AS VentManufacturingTypeDescr,
                            VentOutletGrade,
                            VentOutletWallthickness,
                            VentInletDiameter,
                            VentInletGrade,
                            VentInletWallThickness,
                            VentPressureRating,
                            VentOutletDiameter,
                            c.Code  AS VentConnectCode,
                            c.Descr AS VentConnectDescr
                    FROM   Vent f
                            LEFT JOIN ListDomain c
                                ON f.VentConnectDomainId = c.Id
                            LEFT JOIN ListDomain m
                                ON f.VentManufacturingTypeLd = m.Id
                            LEFT JOIN ListDomain t
                                ON f.VentTypeDomainId = t.Id ) tbl ';
                            
        EXECUTE IMMEDIATE INF_sql;    

        END;
        
        DECLARE 
            SQL_STMT VARCHAR(20000) :=null;                     

        BEGIN

            SQL_STMT := 'INSERT INTO ListDomain
                        (Id,
                        DomainCatalogId,
                        Code,
                        Descr,
                        SourceDomainId)
            SELECT Row_number()OVER(ORDER BY Code)
                + ( SELECT Max( Id )
                    FROM   ListDomain )                       AS Id,
                ( SELECT DomainCatalogId
                    FROM   DomainCatalogColXRef
                    WHERE  TableName = ''Fabrication'' AND
                            ColumnName = ''FabricationTypeDomainId'' ) AS DomainCatalogId,
                tbl.Code,
                tbl.Descr,
                NULL                                              AS SourceDomainId
            FROM   ( SELECT DISTINCT FabricationTypeDomainCode AS Code,
                                    FabricationTypeDomainDesc AS Descr
                    FROM   temp_Fabrication
                    WHERE  FabricationTypeDomainCode IS NOT NULL ) tbl
            WHERE  tbl.Code NOT IN ( SELECT Code
                                    FROM   ListDomain
                                    WHERE  DomainCatalogId =
                                            ( SELECT DomainCatalogId
                                            FROM   DomainCatalogColXRef
                                            WHERE  TableName = ''Fabrication'' AND
                                                    ColumnName = ''FabricationTypeDomainId'') )';
                                                
            EXECUTE IMMEDIATE SQL_STMT;

            SQL_STMT := 'INSERT INTO ListDomain
                        (Id,
                        DomainCatalogId,
                        Code,
                        Descr,
                        SourceDomainId)
            SELECT Row_number()OVER(ORDER BY Code)
                + ( SELECT Max( Id )
                    FROM   ListDomain )                              AS Id,
                ( SELECT DomainCatalogId
                    FROM   DomainCatalogColXRef
                    WHERE  TableName = ''Fabrication'' AND
                            ColumnName = ''FabricationManufacturingTypeLd'' ) AS DomainCatalogId,
                tbl.Code,
                tbl.Descr,
                NULL                                                     AS SourceDomainId
            FROM   ( SELECT DISTINCT FabricationManufacturingTypeCode AS Code,
                                    FabricationManufacturingTypeDesc AS Descr
                    FROM   temp_Fabrication
                    WHERE  FabricationManufacturingTypeCode IS NOT NULL ) tbl
            WHERE  tbl.Code NOT IN ( SELECT Code
                                    FROM   ListDomain
                                    WHERE  DomainCatalogId =
                                            ( SELECT DomainCatalogId
                                            FROM   DomainCatalogColXRef
                                            WHERE  TableName = ''Fabrication'' AND
                                                    ColumnName = ''FabricationManufacturingTypeLd'' ) )';

            EXECUTE IMMEDIATE SQL_STMT;

            SQL_STMT := 'INSERT INTO ListDomain
                        (Id,
                        DomainCatalogId,
                        Code,
                        Descr,
                        SourceDomainId)
            SELECT Row_number()OVER(ORDER BY Code)
                + ( SELECT Max( Id )
                    FROM   ListDomain )                          AS Id,
                ( SELECT DomainCatalogId
                    FROM   DomainCatalogColXRef
                    WHERE  TableName = ''Fabrication'' AND
                            ColumnName = ''FabricationConnectDomainID'' ) AS DomainCatalogId,
                tbl.Code,
                tbl.Descr,
                NULL                                                 AS SourceDomainId
            FROM   ( SELECT DISTINCT FabricationConnectCode AS Code,
                                    FabricationConnectDesc AS Descr
                    FROM   temp_Fabrication
                    WHERE  FabricationConnectCode IS NOT NULL ) tbl
            WHERE  tbl.Code NOT IN ( SELECT Code
                                    FROM   ListDomain
                                    WHERE  DomainCatalogId =
                                            ( SELECT DomainCatalogId
                                            FROM   DomainCatalogColXRef
                                            WHERE  TableName = ''Fabrication'' AND
                                                    ColumnName = ''FabricationConnectDomainID'' ) )';


            EXECUTE IMMEDIATE SQL_STMT;
                
                    
            SQL_STMT := 'Update temp_Fabrication 
            set FabricationTypeDomainId = (Select max(t.Id) from ListDomain t left join  temp_Fabrication f  ON f.FabricationTypeDomainCode = t.Code AND
                            t.DomainCatalogId in
                            ( SELECT DomainCatalogId
                            FROM   DomainCatalogColXRef
                            WHERE  TableName = ''Fabrication'' AND
                                    ColumnName = ''FabricationTypeDomainId'' ))';

            EXECUTE IMMEDIATE SQL_STMT;

            SQL_STMT := 'Update temp_Fabrication 
            set FabricationManufacturingTypeLd = (Select max(m.Id) from ListDomain m left join  temp_Fabrication f  ON f.FabricationTypeDomainCode = m.Code AND
                            m.DomainCatalogId in
                            ( SELECT DomainCatalogId
                            FROM   DomainCatalogColXRef
                            WHERE  TableName = ''Fabrication'' AND
                                    ColumnName = ''FabricationManufacturingTypeLd'' ))';

            EXECUTE IMMEDIATE SQL_STMT;

            SQL_STMT := 'Update temp_Fabrication 
            set FabricationConnectDomainID = (Select max(c.Id) from ListDomain c left join  temp_Fabrication f  ON f.FabricationTypeDomainCode = c.Code AND
                            c.DomainCatalogId in
                            ( SELECT DomainCatalogId
                            FROM   DomainCatalogColXRef
                            WHERE  TableName = ''Fabrication'' AND
                                    ColumnName = ''FabricationConnectDomainID'' ))';

            EXECUTE IMMEDIATE SQL_STMT;

            EXECUTE IMMEDIATE 'UPDATE FabricationRemark SET FabricationId = NULL';
            EXECUTE IMMEDIATE 'UPDATE FacilityAlignment SET FabricationId = NULL';

            EXECUTE IMMEDIATE 'DELETE FROM Fabrication';


            SQL_STMT := 'INSERT INTO Fabrication
                        (Id,
                        EffectiveStartDate,
                        EffectiveEndDate,
                        FabricationTypeDomainId,
                        FabricationOutsideDiameter,
                        FabricationName,
                        FabricationComment,
                        StationSeriesId,
                        StationNum,
                        FabricationManufacturingTypeLd,
                        FabricationOutletGrade,
                        FabricationOutletWallthickness,
                        FabricationInletDiameter,
                        FabricationInletGrade,
                        FabricationInletWallThickness,
                        FabricationPressureRating,
                        FabricationOutletDiameter,
                        FabricationConnectDomainID,
                        BeginStationSeriesId,
                        BeginStationNum,
                        EndStationSeriesId,
                        EndStationNum)
            SELECT Id,
                EffectiveStartDate,
                EffectiveEndDate,
                FabricationTypeDomainId,
                FabricationOutsideDiameter,
                FabricationName,
                FabricationComment,
                StationSeriesId,
                StationNum,
                FabricationManufacturingTypeLd,
                FabricationOutletGrade,
                FabricationOutletWallthickness,
                FabricationInletDiameter,
                FabricationInletGrade,
                FabricationInletWallThickness,
                FabricationPressureRating,
                FabricationOutletDiameter,
                FabricationConnectDomainID,
                StationSeriesId,
                StationNum,
                StationSeriesId,
                StationNum
            FROM   temp_Fabrication ';

            EXECUTE IMMEDIATE SQL_STMT;
        END;

        EXECUTE IMMEDIATE 'DROP TABLE temp_Fabrication';

        COMMIT;
        END;

        END;
    /
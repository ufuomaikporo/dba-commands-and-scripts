IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'ACVG Survey Contractor')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'ACVG Survey Contractor'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'ACVGSurvey'
                        AND     
						ColumnName = 'ACVGSurveyContractorDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'ACVGSurvey'                  ,
                                        'ACVGSurveyContractorDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'ACVG Survey Contractor'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'ACVG Survey Equipment')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'ACVG Survey Equipment'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'ACVGSurvey'
                        AND     
					   ColumnName = 'ACVGSurveyEquipmentDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'ACVGSurvey'                 ,
                                        'ACVGSurveyEquipmentDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'ACVG Survey Equipment'
                        END



IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'ACVG Survey Type')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'ACVG Survey Type'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'ACVGSurvey'
                        AND     ColumnName = 'ACVGSurveyTypeDomainid')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'ACVGSurvey'            ,
                                        'ACVGSurveyTypeDomainid',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'ACVG Survey Type'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'ACVG Anomoly Indication Type')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'ACVG Anomoly Indication Type'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'ACVGSurveyAnomaly'
                        AND     ColumnName = 'ACVGAnomalyIndicationTypeLD')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'ACVGSurveyAnomaly'          ,
                                        'ACVGAnomalyIndicationTypeLD',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'ACVG Anomoly Indication Type'
                        END



IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'ACVG Severity Type')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'ACVG Severity Type'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'ACVGSurveyAnomaly'
                        AND     
						ColumnName = 'ACVGAnomalySeverityTypeLD')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'ACVGSurveyAnomaly'        ,
                                        'ACVGAnomalySeverityTypeLD',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'ACVG Severity Type'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'ACVG Reading Coating Conductance')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'ACVG Reading Coating Conductance'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'ACVGSurveyReading'
                        AND     ColumnName = 'ACVGReadingCoatingConductance')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'ACVGSurveyReading'            ,
                                        'ACVGReadingCoatingConductance',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'ACVG Reading Coating Conductance'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'ACVG Reading Coating Resistance')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'ACVG Reading Coating Resistance'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'ACVGSurveyReading'
                        AND     ColumnName = 'ACVGReadingCoatingResistance')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'ACVGSurveyReading'           ,
                                        'ACVGReadingCoatingResistance',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'ACVG Reading Coating Resistance'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'ACVG Reading Current Direction')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'ACVG Reading Current Direction'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'ACVGSurveyReading'
                        AND     ColumnName = 'ACVGReadingCurrentDirection')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'ACVGSurveyReading'          ,
                                        'ACVGReadingCurrentDirection',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'ACVG Reading Current Direction'
                        END



IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'ACVG Reading Severity Classification')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'ACVG Reading Severity Classification'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'ACVGSurveyReading'
                        AND     ColumnName = 'ACVGReadingSevClassification')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'ACVGSurveyReading'           ,
                                        'ACVGReadingSevClassification',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'ACVG Reading Severity Classification'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Class Area Rating')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Class Area Rating'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'CalcClassArea'
                        AND     ColumnName = 'CalcClassAreaRatingDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'CalcClassArea'              ,
                                        'CalcClassAreaRatingDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Class Area Rating'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Casing Inhibitor')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Casing Inhibitor'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'Casing'
                        AND     ColumnName = 'CasingInhibitorDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'Casing'                 ,
                                        'CasingInhibitorDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Casing Inhibitor'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Structure Type')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Structure Type'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'ClassLocationStructCtgry'
                       AND     
						ColumnName = 'StructureTypeDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'ClassLocationStructCtgry',
                                        'StructureTypeDomainId'   ,
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Structure Type'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'DCVG Survey Contractor')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'DCVG Survey Contractor'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'DCVGSurvey'
                        AND     ColumnName = 'DCVGSurveyContractorDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'DCVGSurvey'                  ,
                                        'DCVGSurveyContractorDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'DCVG Survey Contractor'
                        END



IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'DCVG Survey Equipment')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'DCVG Survey Equipment'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'DCVGSurvey'
                        AND     ColumnName = 'DCVGSurveyEquipmentDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'DCVGSurvey'                 ,
                                        'DCVGSurveyEquipmentDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'DCVG Survey Equipment'
                        END



IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'DCVG Survey Type')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'DCVG Survey Type'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'DCVGSurvey'
                        AND     ColumnName = 'DCVGSurveyTypeDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'DCVGSurvey'            ,
                                        'DCVGSurveyTypeDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'DCVG Survey Type'
                        END



IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'DCVG Anomaly Indication')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'DCVG Anomaly Indication'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'DCVGSurveyAnomaly'
                        AND     ColumnName = 'DCVGAnomalyIndicationTypeLD')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'DCVGSurveyAnomaly'          ,
                                        'DCVGAnomalyIndicationTypeLD',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'DCVG Anomaly Indication'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'DCVG Anomaly Severity')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'DCVG Anomaly Severity'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'DCVGSurveyAnomaly'
                        AND     ColumnName = 'DCVGAnomalySeverityTypeLD')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'DCVGSurveyAnomaly'        ,
                                        'DCVGAnomalySeverityTypeLD',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'DCVG Anomaly Severity'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Class Area Rating')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Class Area Rating'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'DesignClass'
                        AND     ColumnName = 'DesignClassRatingDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'DesignClass'              ,
                                        'DesignClassRatingDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Class Area Rating'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Distribution Population Density')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Distribution Population Density'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'DistPopulationDensity'
                        AND     ColumnName = 'PopulationDensityDomainID')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'DistPopulationDensity'    ,
                                        'PopulationDensityDomainID',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Distribution Population Density'
                        END



IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Distribution Service Head Susceptibility')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Distribution Service Head Susceptibility'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'DistServiceHeadSuscept'
                        AND     ColumnName = 'ServiceHeadSusceptDomainID')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'DistServiceHeadSuscept'    ,
                                        'ServiceHeadSusceptDomainID',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Distribution Service Head Susceptibility'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'OF Seismic Ranking')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'OF Seismic Ranking'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'EarthQuakeArea'
                        AND     ColumnName = 'EarthQuakeAreaRangeLD')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'EarthQuakeArea'       ,
                                        'EarthQuakeAreaRangeLD',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'OF Seismic Ranking'
                        END



IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Fabrication Manufacturing Type')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Fabrication Manufacturing Type'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'Fabrication'
                        AND     ColumnName = 'FabricationManufacturingTypeLd')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'Fabrication'                   ,
                                        'FabricationManufacturingTypeLd',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Fabrication Manufacturing Type'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Coordinate System')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Coordinate System'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'Facility'
                        AND     ColumnName = 'FacilityCoordSysDomainid')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'Facility'                ,
                                        'FacilityCoordSysDomainid',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Coordinate System'
                        END

					
IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'ILI Facility Status')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'ILI Facility Status'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'Facility'
                        AND     ColumnName = 'FacilityLocationDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'Facility'                ,
                                        'FacilityLocationDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'ILI Facility Status'
                        END



IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'ILI Facility Status')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'ILI Facility Status'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'Facility'
                        AND     ColumnName = 'FacilityOperatorDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'Facility'                ,
                                        'FacilityOperatorDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'ILI Facility Status'
                        END



IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'ILI Facility Status')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'ILI Facility Status'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'Facility'
                        AND     ColumnName = 'FacilityOwnerDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'Facility'             ,
                                        'FacilityOwnerDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'ILI Facility Status'
                        END



IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'ILI Facility Status')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'ILI Facility Status'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'Facility'
                        AND     ColumnName = 'FacilityStatusDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'Facility'              ,
                                        'FacilityStatusDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'ILI Facility Status'
                        END



IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'ILI Facility Type')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'ILI Facility Type'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'Facility'
                        AND     ColumnName = 'FacilityTypeDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'Facility'            ,
                                        'FacilityTypeDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'ILI Facility Type'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Facility Flow Product Type')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Facility Flow Product Type'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'FacilityFlow'
                        AND     ColumnName = 'FacilityFlowProdTypeDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'FacilityFlow'                ,
                                        'FacilityFlowProdTypeDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Facility Flow Product Type'
                        END



IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'FAULT AREA DIP DIRECTION')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'FAULT AREA DIP DIRECTION'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'FaultArea'
                        AND     ColumnName = 'FaultAreaDipDirectionLD')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'FaultArea'              ,
                                        'FaultAreaDipDirectionLD',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'FAULT AREA DIP DIRECTION'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Fault Area Slip Rate')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Fault Area Slip Rate'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'FaultArea'
                        AND     ColumnName = 'FaultAreaSlipRateLD')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'FaultArea'          ,
                                        'FaultAreaSlipRateLD',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Fault Area Slip Rate'
                        END



IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'FAULT AREA SLIP SENSE')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'FAULT AREA SLIP SENSE'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'FaultArea'
                        AND     ColumnName = 'FaultAreaSlipSenseLD')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'FaultArea'           ,
                                        'FaultAreaSlipSenseLD',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'FAULT AREA SLIP SENSE'
                        END



IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'OF Flood Ranking')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'OF Flood Ranking'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'FloodArea'
                        AND     ColumnName = 'FloodAreaLD')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'FloodArea'  ,
                                        'FloodAreaLD',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'OF Flood Ranking'
                        END



IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'OF Flood Ranking')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'OF Flood Ranking'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'FloodArea'
                        AND     ColumnName = 'FloodAreaRangeLD')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'FloodArea'       ,
                                        'FloodAreaRangeLD',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'OF Flood Ranking'
                        END



IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'FROST AREA RANGE')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'FROST AREA RANGE'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'FrostArea'
                        AND     ColumnName = 'FrostAreaRangeLD')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'FrostArea'       ,
                                        'FrostAreaRangeLD',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'FROST AREA RANGE'
                        END



IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'State / Province Name')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'State / Province Name'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'HurricaneArea'
                        AND     ColumnName = 'HurricaneAreaLD')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'HurricaneArea'  ,
                                        'HurricaneAreaLD',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'State / Province Name'
                        END



IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'OF Hurricane Ranking')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'OF Hurricane Ranking'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'HurricaneArea'
                        AND     ColumnName = 'HurricaneAreaRangeLD')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'HurricaneArea'       ,
                                        'HurricaneAreaRangeLD',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'OF Hurricane Ranking'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Affected Part')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Affected Part'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'IncidentDetails'
                        AND     ColumnName = 'AffectedPartDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'IncidentDetails'     ,
                                        'AffectedPartDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Affected Part'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Coordinate System')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Coordinate System'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'IncidentDetails'
                        AND     ColumnName = 'IncidentCoordSysDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'IncidentDetails'         ,
                                        'IncidentCoordSysDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Coordinate System'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'LineLoopType')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'LineLoopType'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'IncidentDetails'
                        AND     ColumnName = 'LocationTypeDomainID')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'IncidentDetails'     ,
                                        'LocationTypeDomainID',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'LineLoopType'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Distribution Population Density')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Distribution Population Density'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'IncidentDetails'
                        AND     ColumnName = 'PopulationDensityDomainID')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'IncidentDetails'          ,
                                        'PopulationDensityDomainID',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Distribution Population Density'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'PressureClass')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'PressureClass'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'IncidentDetails'
                        AND     ColumnName = 'PressureClassDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'IncidentDetails'      ,
                                        'PressureClassDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'PressureClass'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Primary Coating')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Primary Coating'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'IncidentDetails'
                        AND     ColumnName = 'PrimaryCoatingDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'IncidentDetails'       ,
                                        'PrimaryCoatingDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Primary Coating'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Primary Pipe Material')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Primary Pipe Material'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'IncidentDetails'
                        AND     ColumnName = 'PrimaryPipeMaterialDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'IncidentDetails'            ,
                                        'PrimaryPipeMaterialDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Primary Pipe Material'
                        END



IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Repair Method')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Repair Method'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'IncidentDetails'
                        AND     ColumnName = 'RepairMethodDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'IncidentDetails'     ,
                                        'RepairMethodDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Repair Method'
                        END



IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Secondary Pipe Material')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Secondary Pipe Material'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'IncidentDetails'
                        AND     ColumnName = 'SecondaryPipeMaterialDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'IncidentDetails'              ,
                                        'SecondaryPipeMaterialDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Secondary Pipe Material'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Distribution Service Head Susceptibility')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Distribution Service Head Susceptibility'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'IncidentDetails'
                        AND     ColumnName = 'ServiceHeadSusceptDomainID')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'IncidentDetails'           ,
                                        'ServiceHeadSusceptDomainID',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Distribution Service Head Susceptibility'
                        END



IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Incident Severity')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Incident Severity'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'IncidentDetails'
                        AND     ColumnName = 'SeverityDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'IncidentDetails' ,
                                        'SeverityDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Incident Severity'
                        END



IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Incident Status')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Incident Status'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'IncidentDetails'
                        AND     ColumnName = 'StatusDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'IncidentDetails',
                                        'StatusDomainId' ,
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Incident Status'
                        END



IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Classification Type')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Classification Type'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'IncidentDetails'
                        AND     ColumnName = 'TypeDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'IncidentDetails',
                                        'TypeDomainId'   ,
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Classification Type'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Failure Pressure Algorithm')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Failure Pressure Algorithm'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'InlineInspectionCrackAnomaly'
                        AND     ColumnName = 'ILICAFailPressAlgthmDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'InlineInspectionCrackAnomaly',
                                        'ILICAFailPressAlgthmDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Failure Pressure Algorithm'
                        END



IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Coordinate System')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Coordinate System'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'InlineInspectionCrsnCallBox'
                        AND     ColumnName = 'ILICBCoordSysDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'InlineInspectionCrsnCallBox',
                                        'ILICBCoordSysDomainId'      ,
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Coordinate System'
                        END



IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Failure Pressure Algorithm')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Failure Pressure Algorithm'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'InlineInspectionCrsnCallBox'
                        AND     ColumnName = 'ILICBFailPressAlgthmDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'InlineInspectionCrsnCallBox' ,
                                        'ILICBFailPressAlgthmDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Failure Pressure Algorithm'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Coordinate System')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Coordinate System'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'InlineInspectionFacility'
                        AND     ColumnName = 'ILIFacCoordSysDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'InlineInspectionFacility',
                                        'ILIFacCoordSysDomainId'  ,
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Coordinate System'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'ILI Facility Status')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'ILI Facility Status'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'InlineInspectionFacility'
                        AND     ColumnName = 'ILIFacStatusDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'InlineInspectionFacility',
                                        'ILIFacStatusDomainId'    ,
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'ILI Facility Status'
                        END



IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'CFR Grading')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'CFR Grading'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'InlineInspectionFeature'
                        AND     ColumnName = 'CFRGrading1DomainID')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'InlineInspectionFeature',
                                        'CFRGrading1DomainID'    ,
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'CFR Grading'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'CFR Grading')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'CFR Grading'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'InlineInspectionFeature'
                        AND     ColumnName = 'CFRGrading2DomainID')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'InlineInspectionFeature',
                                        'CFRGrading2DomainID'    ,
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'CFR Grading'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Coordinate System')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Coordinate System'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'InlineInspectionFeature'
                        AND     ColumnName = 'ILIFCoordSysDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'InlineInspectionFeature',
                                        'ILIFCoordSysDomainId'   ,
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Coordinate System'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'IRAS NOT AVAILABLE')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'IRAS NOT AVAILABLE'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'InlineInspectionJoint'
                        AND     ColumnName = 'ILIJointCoordSysDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'InlineInspectionJoint'   ,
                                        'ILIJointCoordSysDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'IRAS NOT AVAILABLE'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'CFR Grading')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'CFR Grading'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'InlineInspectionNonCrsnDfct'
                        AND     ColumnName = 'CFRGrading1DomainID')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'InlineInspectionNonCrsnDfct',
                                        'CFRGrading1DomainID'        ,
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'CFR Grading'
                        END



IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'CFR Grading')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'CFR Grading'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'InlineInspectionNonCrsnDfct'
                        AND     ColumnName = 'CFRGrading2DomainID')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'InlineInspectionNonCrsnDfct',
                                        'CFRGrading2DomainID'        ,
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'CFR Grading'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Coordinate System')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Coordinate System'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'InlineInspectionNonCrsnDfct'
                        AND     ColumnName = 'ILINCDCoordSysDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'InlineInspectionNonCrsnDfct',
                                        'ILINCDCoordSysDomainId'     ,
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Coordinate System'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'ILI Non Crsn Dfct Status')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'ILI Non Crsn Dfct Status'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'InlineInspectionNonCrsnDfct'
                        AND     ColumnName = 'ILINCDStatusDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'InlineInspectionNonCrsnDfct',
                                        'ILINCDStatusDomainId'       ,
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'ILI Non Crsn Dfct Status'
                        END



IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'ILI Remark Type')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'ILI Remark Type'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'InlineInspectionRemark'
                        AND     ColumnName = 'ILIRemarkTypeDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'InlineInspectionRemark',
                                        'ILIRemarkTypeDomainId' ,
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'ILI Remark Type'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'State / Province Name')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'State / Province Name'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'LandSlideArea'
                        AND     ColumnName = 'LandSlideAreaLD')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'LandSlideArea'  ,
                                        'LandSlideAreaLD',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'State / Province Name'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'LANDSLIDE AREA RANGE')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'LANDSLIDE AREA RANGE'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'LandSlideArea'
                        AND     ColumnName = 'LandSlideAreaRangeLD')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'LandSlideArea'       ,
                                        'LandSlideAreaRangeLD',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'LANDSLIDE AREA RANGE'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Lightning Strike Area Range')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Lightning Strike Area Range'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'LightningStrikeArea'
                        AND     ColumnName = 'LightningStrikeAreaRangeLD')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'LightningStrikeArea'       ,
                                        'LightningStrikeAreaRangeLD',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Lightning Strike Area Range'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Maintenance Status')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Maintenance Status'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'Maintenance'
                        AND     ColumnName = 'MaintenanceStatusDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'Maintenance'              ,
                                        'MaintenanceStatusDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Maintenance Status'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Maintenance Type')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Maintenance Type'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'Maintenance'
                        AND     ColumnName = 'MaintenanceTypeDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'Maintenance'            ,
                                        'MaintenanceTypeDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Maintenance Type'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Maintenance Project Company')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Maintenance Project Company'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'MaintenanceProject'
                        AND     ColumnName = 'MaintenanceProjCompanyDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'MaintenanceProject'            ,
                                        'MaintenanceProjCompanyDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Maintenance Project Company'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Maintenance Project Status')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Maintenance Project Status'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'MaintenanceProject'
                        AND     ColumnName = 'MaintenanceProjStatusDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'MaintenanceProject'           ,
                                        'MaintenanceProjStatusDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Maintenance Project Status'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Maintenance Project Type')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Maintenance Project Type'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'MaintenanceProject'
                        AND     ColumnName = 'MaintenanceProjTypeDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'MaintenanceProject'         ,
                                        'MaintenanceProjTypeDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Maintenance Project Type'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Coordinate System')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Coordinate System'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'NodeConnection'
                        AND     ColumnName = 'NodeConnectionCoordSysLD')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'NodeConnection'          ,
                                        'NodeConnectionCoordSysLD',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Coordinate System'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Node Connection Status')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Node Connection Status'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'NodeConnection'
                        AND     ColumnName = 'NodeConnectionStatusDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'NodeConnection'              ,
                                        'NodeConnectionStatusDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Node Connection Status'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Node Connection Type')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Node Connection Type'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'NodeConnection'
                        AND     ColumnName = 'NodeConnectionTypeDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'NodeConnection'            ,
                                        'NodeConnectionTypeDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Node Connection Type'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Outside Force Type')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Outside Force Type'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'OutsideForces'
                        AND     ColumnName = 'OutsideForceTypeDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'OutsideForces'           ,
                                        'OutsideForceTypeDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Outside Force Type'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'PCM Reading Coating Resistance')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'PCM Reading Coating Resistance'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'PCMSurveyReading'
                        AND     ColumnName = 'PCMREADINGCOATINGRESISTANCE')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'PCMSurveyReading'           ,
                                        'PCMREADINGCOATINGRESISTANCE',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'PCM Reading Coating Resistance'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Coordinate System')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Coordinate System'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'PCMSurveyReading'
                        AND     ColumnName = 'PCMREADINGCOORDSYSDOMAINID')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'PCMSurveyReading'          ,
                                        'PCMREADINGCOORDSYSDOMAINID',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Coordinate System'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'PCM Reading Current Direction')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'PCM Reading Current Direction'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'PCMSurveyReading'
                        AND     ColumnName = 'PCMREADINGCURRENTDIRECTION')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'PCMSurveyReading'          ,
                                        'PCMREADINGCURRENTDIRECTION',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'PCM Reading Current Direction'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'PCM Reading Severity Classification')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'PCM Reading Severity Classification'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'PCMSurveyReading'
                        AND     ColumnName = 'PCMREADINGSEVCLASSIFICATION')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'PCMSurveyReading'           ,
                                        'PCMREADINGSEVCLASSIFICATION',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'PCM Reading Severity Classification'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Pipe Subtype')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Pipe Subtype'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'PipeSegment'
                        AND     ColumnName = 'PipeSubtypeDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'PipeSegment'        ,
                                        'PipeSubtypeDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Pipe Subtype'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Coating Type - Line')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Coating Type - Line'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'POECoatingProperty'
                        AND     ColumnName = 'CoatingLineDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'POECoatingProperty' ,
                                        'CoatingLineDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Coating Type - Line'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'ILI Company')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'ILI Company'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'POECompanyLookup'
                        AND     ColumnName = 'ILICompanyDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'POECompanyLookup'  ,
                                        'ILICompanyDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'ILI Company'
                        END



IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Metal Loss Type')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Metal Loss Type'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'POECompanyLookUp'
                        AND     ColumnName = 'MetalLossTypeDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'POECompanyLookUp'     ,
                                        'MetalLossTypeDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Metal Loss Type'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Class Area Rating')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Class Area Rating'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'RCCSAClassCalcSeg'
                        AND     ColumnName = 'RCCSACALCSEGCLASSAREARATINGLD')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'RCCSAClassCalcSeg'            ,
                                        'RCCSACALCSEGCLASSAREARATINGLD',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Class Area Rating'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Class Area Rating')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Class Area Rating'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'RCCSAClassCalcSeg'
                        AND     ColumnName = 'RCCSACALCSEGDSGNCLASSRATINGLD')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'RCCSAClassCalcSeg'            ,
                                        'RCCSACALCSEGDSGNCLASSRATINGLD',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Class Area Rating'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Class Area Rating')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Class Area Rating'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'RCCSAClassCalcSeg'
                        AND     ColumnName = 'RCCSACALCSEGRATINGLD')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'RCCSAClassCalcSeg'   ,
                                        'RCCSACALCSEGRATINGLD',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Class Area Rating'
                        END



IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Fabrication Type')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Fabrication Type'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'RCMAOPCalcSeg'
                        AND     ColumnName = 'FabricationTypeDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'RCMAOPCalcSeg'          ,
                                        'FabricationTypeDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Fabrication Type'
                        END



IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Pipe Subtype')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Pipe Subtype'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'RCMAOPCalcSeg'
                        AND     ColumnName = 'PipeSubTypeDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'RCMAOPCalcSeg'      ,
                                        'PipeSubTypeDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Pipe Subtype'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Class Area Rating')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Class Area Rating'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'RCMAOPCalcSeg'
                        AND     ColumnName = 'RCMAOPCSEGCLASSAREARATINGLD')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'RCMAOPCalcSeg'              ,
                                        'RCMAOPCSEGCLASSAREARATINGLD',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Class Area Rating'
                        END



IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Class Area Rating')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Class Area Rating'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'RCMAOPCalcSeg'
                        AND     ColumnName = 'RCMAOPCSEGDSGNCLASSRATINGLD')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'RCMAOPCalcSeg'              ,
                                        'RCMAOPCSEGDSGNCLASSRATINGLD',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Class Area Rating'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Pipe Material')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Pipe Material'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'RCMAOPCalcSeg'
                        AND     ColumnName = 'RCMAOPCSEGPIPEMATERIALLD')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'RCMAOPCalcSeg'           ,
                                        'RCMAOPCSEGPIPEMATERIALLD',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Pipe Material'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Pipe Specification')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Pipe Specification'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'RCMAOPCalcSeg'
                        AND     ColumnName = 'RCMAOPCSEGPMSPECID')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'RCMAOPCalcSeg'     ,
                                        'RCMAOPCSEGPMSPECID',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Pipe Specification'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Right of Way Owner')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Right of Way Owner'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'RightOfWay'
                        AND     ColumnName = 'ROWOwnerDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'RightOfWay'      ,
                                        'ROWOwnerDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Right of Way Owner'
                        END



IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Right of Way Type')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Right of Way Type'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'RightOfWay'
                        AND     ColumnName = 'ROWTypeDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'RightOfWay'     ,
                                        'ROWTypeDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Right of Way Type'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Coordinate System')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Coordinate System'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'SoilEnvironment'
                        AND     ColumnName = 'SoilCoordSysDomainid')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'SoilEnvironment'     ,
                                        'SoilCoordSysDomainid',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Coordinate System'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Soil Drainage')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Soil Drainage'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'SoilEnvironment'
                        AND     ColumnName = 'SoilDrainageDomainid')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'SoilEnvironment'     ,
                                        'SoilDrainageDomainid',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Soil Drainage'
                        END



IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Soil Topography')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Soil Topography'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'SoilEnvironment'
                        AND     ColumnName = 'SoilMacroEnvDomainid')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'SoilEnvironment'     ,
                                        'SoilMacroEnvDomainid',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Soil Topography'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Soil Land Use')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Soil Land Use'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'SoilEnvironment'
                        AND     ColumnName = 'SoilTopographyDomainid')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'SoilEnvironment'       ,
                                        'SoilTopographyDomainid',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Soil Land Use'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'StationSeries Attribute LD1')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'StationSeries Attribute LD1'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'StationSeriesAttribute'
                        AND     ColumnName = 'AttributeListDomainID1')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'StationSeriesAttribute',
                                        'AttributeListDomainID1',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'StationSeries Attribute LD1'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'StationSeries Attribute LD 2')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'StationSeries Attribute LD 2'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'StationSeriesAttribute'
                        AND     ColumnName = 'AttributeListDomainID2')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'StationSeriesAttribute',
                                        'AttributeListDomainID2',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'StationSeries Attribute LD 2'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'StationSeries Attribute LD 3')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'StationSeries Attribute LD 3'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'StationSeriesAttribute'
                        AND     ColumnName = 'AttributeListDomainID3')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'StationSeriesAttribute',
                                        'AttributeListDomainID3',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'StationSeries Attribute LD 3'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'StationSeries Attribute LD 4')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'StationSeries Attribute LD 4'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'StationSeriesAttribute'
                        AND     ColumnName = 'AttributeListDomainID4')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'StationSeriesAttribute',
                                        'AttributeListDomainID4',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'StationSeries Attribute LD 4'
                        END



IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'StationSeries Attribute LD 5')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'StationSeries Attribute LD 5'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'StationSeriesAttribute'
                        AND     ColumnName = 'AttributeListDomainID5')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'StationSeriesAttribute',
                                        'AttributeListDomainID5',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'StationSeries Attribute LD 5'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'ILI Call Box Interaction rule')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'ILI Call Box Interaction rule'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'Stg_ILI'
                        AND     ColumnName = 'ILICallBoxInteractRuleDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'Stg_ILI'                       ,
                                        'ILICallBoxInteractRuleDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'ILI Call Box Interaction rule'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'ILI Company')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'ILI Company'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'Stg_ILI'
                        AND     ColumnName = 'ILICompanyDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'Stg_ILI'           ,
                                        'ILICompanyDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'ILI Company'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Datum')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Datum'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'Stg_ILI'
                        AND     ColumnName = 'ILICoordDatumDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'Stg_ILI'              ,
                                        'ILICoordDatumDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Datum'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Coordinate Projection')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Coordinate Projection'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'Stg_ILI'
                        AND     ColumnName = 'ILICoordProjDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'Stg_ILI'             ,
                                        'ILICoordProjDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Coordinate Projection'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'ILI FPA')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'ILI FPA'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'Stg_ILI'
                        AND     ColumnName = 'ILIFPADomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'Stg_ILI'       ,
                                        'ILIFPADomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'ILI FPA'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'ILI Call Box Interaction rule')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'ILI Call Box Interaction rule'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'Stg_ILI'
                        AND     ColumnName = 'ILIGroupBoxIntRuleDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'Stg_ILI'                   ,
                                        'ILIGroupBoxIntRuleDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'ILI Call Box Interaction rule'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Datum')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Datum'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'Stg_ILI'
                        AND     ColumnName = 'ILIHeightDatumDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'Stg_ILI'               ,
                                        'ILIHeightDatumDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Datum'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'ILI Status')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'ILI Status'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'Stg_ILI'
                        AND     ColumnName = 'ILIStatusDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'Stg_ILI'          ,
                                        'ILIStatusDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'ILI Status'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'ILI Tool')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'ILI Tool'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'Stg_ILI'
                        AND     ColumnName = 'ILIToolDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'Stg_ILI'        ,
                                        'ILIToolDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'ILI Tool'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'ILI Tool')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'ILI Tool'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'Stg_ILI'
                        AND     ColumnName = 'ILITypeDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'Stg_ILI'        ,
                                        'ILITypeDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'ILI Tool'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Axial Strain Available Analysis Type')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Axial Strain Available Analysis Type'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'Stg_ILIAxialStrain'
                        AND     ColumnName = 'ILIASAnalysisDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'Stg_ILIAxialStrain'   ,
                                        'ILIASAnalysisDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Axial Strain Available Analysis Type'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Bend Strain Type')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Bend Strain Type'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'Stg_ILIBendStrain'
                        AND     ColumnName = 'ILIBSTypeDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'Stg_ILIBendStrain',
                                        'ILIBSTypeDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Bend Strain Type'
                        END



IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'ILI Crack Depth')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'ILI Crack Depth'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'Stg_ILICrackAnomaly'
                        AND     ColumnName = 'ILICADepthDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'Stg_ILICrackAnomaly',
                                        'ILICADepthDomainId' ,
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'ILI Crack Depth'
                        END



IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Failure Pressure Algorithm')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Failure Pressure Algorithm'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'Stg_ILICrackAnomaly'
                        AND     ColumnName = 'ILICAFailPressAlgthmDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'Stg_ILICrackAnomaly'         ,
                                        'ILICAFailPressAlgthmDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Failure Pressure Algorithm'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'ILI Feature Grading 1')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'ILI Feature Grading 1'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'Stg_ILICrackAnomaly'
                        AND     ColumnName = 'ILICAGrading1DomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'Stg_ILICrackAnomaly'  ,
                                        'ILICAGrading1DomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'ILI Feature Grading 1'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'ILI Crack Grading 2')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'ILI Crack Grading 2'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'Stg_ILICrackAnomaly'
                        AND     ColumnName = 'ILICAGrading2DomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'Stg_ILICrackAnomaly'  ,
                                        'ILICAGrading2DomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'ILI Crack Grading 2'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'ILI Defect Status')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'ILI Defect Status'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'Stg_ILICrackAnomaly'
                        AND     ColumnName = 'ILICAStatusDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'Stg_ILICrackAnomaly',
                                        'ILICAStatusDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'ILI Defect Status'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Failure Pressure Algorithm')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Failure Pressure Algorithm'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'Stg_ILICrsnCallBox'
                        AND     ColumnName = 'ILICBFailPressAlgthmDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'Stg_ILICrsnCallBox'          ,
                                        'ILICBFailPressAlgthmDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Failure Pressure Algorithm'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'ILI Defect Status')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'ILI Defect Status'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'Stg_ILICrsnCallBox'
                        AND     ColumnName = 'ILICBStatusDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'Stg_ILICrsnCallBox' ,
                                        'ILICBStatusDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'ILI Defect Status'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'ILI Facility Type')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'ILI Facility Type'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'Stg_ILIFacility'
                        AND     ColumnName = 'ILIFacTypeDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'Stg_ILIFacility'   ,
                                        'ILIFacTypeDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'ILI Facility Type'
                        END



IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'CFR Grading')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'CFR Grading'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'Stg_ILIFeature'
                        AND     ColumnName = 'CFRGrading1DomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'Stg_ILIFeature'     ,
                                        'CFRGrading1DomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'CFR Grading'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'CFR Grading')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'CFR Grading'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'Stg_ILIFeature'
                        AND     ColumnName = 'CFRGrading2DomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'Stg_ILIFeature'     ,
                                        'CFRGrading2DomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'CFR Grading'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'ILI Feature Grading 1 - Response Time')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'ILI Feature Grading 1 - Response Time'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'Stg_ILIFeature'
                        AND     ColumnName = 'ILIFGrading1DomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'Stg_ILIFeature'      ,
                                        'ILIFGrading1DomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'ILI Feature Grading 1 - Response Time'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'ILI Feature Grading 2 - Criteria')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'ILI Feature Grading 2 - Criteria'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'Stg_ILIFeature'
                        AND     ColumnName = 'ILIFGrading2DomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'Stg_ILIFeature'      ,
                                        'ILIFGrading2DomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'ILI Feature Grading 2 - Criteria'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'ILI Defect Status')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'ILI Defect Status'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'Stg_ILIFeature'
                        AND     ColumnName = 'ILIFStatusDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'Stg_ILIFeature'    ,
                                        'ILIFStatusDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'ILI Defect Status'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'ILI Feature Type')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'ILI Feature Type'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'Stg_ILIFeature'
                        AND     ColumnName = 'ILIFTypeDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'Stg_ILIFeature'  ,
                                        'ILIFTypeDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'ILI Feature Type'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'CFR Grading')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'CFR Grading'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'Stg_ILINonCrsnDfct'
                        AND     ColumnName = 'CFRGrading1DomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'Stg_ILINonCrsnDfct' ,
                                        'CFRGrading1DomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'CFR Grading'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'CFR Grading')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'CFR Grading'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'Stg_ILINonCrsnDfct'
                        AND     ColumnName = 'CFRGrading2DomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'Stg_ILINonCrsnDfct' ,
                                        'CFRGrading2DomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'CFR Grading'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'ILI Feature Grading 1 - Response Time')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'ILI Feature Grading 1 - Response Time'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'Stg_ILINonCrsnDfct'
                        AND     ColumnName = 'ILINCDGrading1DomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'Stg_ILINonCrsnDfct'    ,
                                        'ILINCDGrading1DomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'ILI Feature Grading 1 - Response Time'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'NCD Grading')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'NCD Grading'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'Stg_ILINonCrsnDfct'
                        AND     ColumnName = 'ILINCDGrading2DomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'Stg_ILINonCrsnDfct'    ,
                                        'ILINCDGrading2DomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'NCD Grading'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'ILI Non Crsn Dfct Status')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'ILI Non Crsn Dfct Status'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'Stg_ILINonCrsnDfct'
                        AND     ColumnName = 'ILINCDStatusDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'Stg_ILINonCrsnDfct'  ,
                                        'ILINCDStatusDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'ILI Non Crsn Dfct Status'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'ILI non Corrosion Defect')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'ILI non Corrosion Defect'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'Stg_ILINonCrsnDfct'
                        AND     ColumnName = 'ILINCDTypeDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'Stg_ILINonCrsnDfct',
                                        'ILINCDTypeDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'ILI non Corrosion Defect'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Failure Pressure Algorithm')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Failure Pressure Algorithm'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'Stg_ILIRange'
                        AND     ColumnName = 'ILIRFailPressAlgthmDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'Stg_ILIRange'               ,
                                        'ILIRFailPressAlgthmDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Failure Pressure Algorithm'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'ILI Status')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'ILI Status'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'Stg_ILIRange'
                        AND     ColumnName = 'ILIRStatusDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'Stg_ILIRange'      ,
                                        'ILIRStatusDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'ILI Status'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'ILI Tool')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'ILI Tool'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'Stg_ILIRange'
                        AND     ColumnName = 'ILIRToolDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'Stg_ILIRange'    ,
                                        'ILIRToolDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'ILI Tool'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Maintenance Type')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Maintenance Type'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'Stg_Maintenance'
                        AND     ColumnName = 'MaintenanceTypeDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'Stg_Maintenance'        ,
                                        'MaintenanceTypeDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Maintenance Type'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Occupancy Category')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Occupancy Category'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'StructOccupancyCtgry'
                        AND     ColumnName = 'OccupancyCtgryDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'StructOccupancyCtgry'  ,
                                        'OccupancyCtgryDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Occupancy Category'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Tank Type')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Tank Type'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'Tank'
                        AND     ColumnName = 'TankTypeDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'Tank'            ,
                                        'TankTypeDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Tank Type'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Shutdown Profile')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Shutdown Profile'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'ValveType'
                        AND     ColumnName = 'ValveTypeClosureProfileLD')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'ValveType'                ,
                                        'ValveTypeClosureProfileLD',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Shutdown Profile'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'ILI Type')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'ILI Type'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'POECompanyLookUp'
                        AND     ColumnName = 'ToolTypeDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'POECompanyLookUp',
                                        'ToolTypeDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'ILI Type'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'Failure Pressure Algorithm')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Failure Pressure Algorithm'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'Stg_ILIFeature'
                        AND     ColumnName = 'ILIFFailPressAlgthmDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'Stg_ILIFeature'             ,
                                        'ILIFFailPressAlgthmDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Failure Pressure Algorithm'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'EC Casing Inhibitor Description')

                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'EC Casing Inhibitor Description'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'CasingDescription'
                        AND     ColumnName = 'CasingDescription')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'CasingDescription'             ,
                                        'CasingDescription',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'EC Casing Inhibitor Description'
                        END
						

IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'EC SME Coating Condition')

                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'EC SME Coating Condition'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'CoatingCondition'
                        AND     ColumnName = 'CoatingCondition')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'CoatingCondition'             ,
                                        'CoatingCondition',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'EC SME Coating Condition'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr = 'IC Coupon Data')
	
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'IC Coupon Data'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'CouponData'
                        AND     ColumnName = 'CouponData')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'CouponData'             ,
                                        'CouponData',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'IC Coupon Data'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr like 'IC Internal Condition')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'IC Internal Condition'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'InternalCondition'
                        AND     ColumnName = 'InternalCondition')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'InternalCondition'             ,
                                        'InternalCondition',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'IC Internal Condition'
                        END



IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr like 'EC Soil Other')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'EC Soil Other'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'SoilOther'
                        AND     ColumnName = 'SoilOther')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'SoilOther'             ,
                                        'SoilOther',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'EC Soil Other'
                        END


IF
        NOT EXISTS
        (
                SELECT
                        *
                FROM
                        DomainCatalog
                WHERE
                        DomainDescr like 'Facility Flow Group Component')
                BEGIN
                        INSERT INTO DomainCatalog
                                (
                                        Id,
                                        DomainDescr
                                )
                        SELECT
                                MAX(Id) + 1,
                                'Facility Flow Group Component'
                        FROM
                                DomainCatalog
                END IF NOT EXISTS
                (
                        SELECT
                                *
                        FROM
                                DomainCatalogColXRef
                        WHERE
                                TableName  = 'FacilityFlowGroupComponent'
                        AND     
						ColumnName = 'FacilityFlowComponentDomainId')
                        BEGIN
                                INSERT INTO DomainCatalogColXRef
                                        (
                                                TableName ,
                                                ColumnName,
                                                DomainCatalogId
                                        )
                                SELECT
                                        'FacilityFlowGroupComponent'             ,
                                        'FacilityFlowComponentDomainId',
                                        Id
                                FROM
                                        DomainCatalog
                                WHERE
                                        DomainDescr = 'Facility Flow Group Component'
                        END




IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Maintenance Status')     
BEGIN    
	INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Maintenance Status' FROM DomainCatalog    
END

IF NOT EXISTS (SELECT * FROM DomainCatalogColXRef WHERE TableName = 'Stg_Maintenance' AND ColumnName = 'MaintenanceStatusDomainId')     
BEGIN      
	INSERT INTO DomainCatalogColXRef (TableName, ColumnName, DomainCatalogId)     
	SELECT 'Stg_Maintenance',  'MaintenanceStatusDomainId', Id      FROM DomainCatalog 
	WHERE DomainDescr = 'Maintenance Status'     
END

IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Soil Land Use')     
BEGIN    
	INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Soil Land Use' FROM DomainCatalog    
END

IF NOT EXISTS (SELECT * FROM DomainCatalogColXRef WHERE TableName = 'SoilMacroEnvironment' AND ColumnName = 'SoilMacroEnvironment')     
BEGIN      
	INSERT INTO DomainCatalogColXRef (TableName, ColumnName, DomainCatalogId)     
	SELECT 'SoilMacroEnvironment',  'SoilMacroEnvironment', Id      FROM DomainCatalog 
	WHERE DomainDescr = 'Soil Land Use'     
END

IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Psproximity')     
BEGIN    
	INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Psproximity' FROM DomainCatalog    
END

IF NOT EXISTS (SELECT * FROM DomainCatalogColXRef WHERE TableName = 'PSProximity' AND ColumnName = 'PSProximity')     
BEGIN      
	INSERT INTO DomainCatalogColXRef (TableName, ColumnName, DomainCatalogId)     
	SELECT 'PSProximity',  'PSProximity', Id      FROM DomainCatalog 
	WHERE DomainDescr = 'Psproximity'     
END

IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Transition Inspection')     
BEGIN    
	INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Transition Inspection' FROM DomainCatalog    
END

IF NOT EXISTS (SELECT * FROM DomainCatalogColXRef WHERE TableName = 'TransitionCorrosion' AND ColumnName = 'TransitionCorrosion')     
BEGIN      
	INSERT INTO DomainCatalogColXRef (TableName, ColumnName, DomainCatalogId)     
	SELECT 'TransitionCorrosion',  'TransitionCorrosion', Id      FROM DomainCatalog 
	WHERE DomainDescr = 'Transition Inspection'     
END

IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Crossing Type')     
BEGIN    
	INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Crossing Type' FROM DomainCatalog    
END

IF NOT EXISTS (SELECT * FROM DomainCatalogColXRef WHERE TableName = 'TPD_Crossing' AND ColumnName = 'TPD_Crossing')     
BEGIN      
	INSERT INTO DomainCatalogColXRef (TableName, ColumnName, DomainCatalogId)     
	SELECT 'TPD_Crossing',  'TPD_Crossing', Id      FROM DomainCatalog 
	WHERE DomainDescr = 'Crossing Type'     
END

UPDATE VirtualTableDataListDomain 
SET DataFieldValueDomainId = 40012
FROM VirtualTableDataListDomain vtld
JOIN VirtualTable vt ON vt.Id = vtld.VirtualTableId
WHERE DataFieldValueDomainId = 10097 AND vt.VirtualTableName = 'FaultLine_R'

UPDATE VirtualTableDataListDomain 
SET DataFieldValueDomainId = 40072
FROM VirtualTableDataListDomain vtld
JOIN VirtualTable vt ON vt.Id = vtld.VirtualTableId
WHERE DataFieldValueDomainId = 10097 AND vt.VirtualTableName = 'DynWater_R'


UPDATE VirtualTableDataListDomain 
SET DataFieldValueDomainId = 40070
FROM VirtualTableDataListDomain vtld
JOIN VirtualTable vt ON vt.Id = vtld.VirtualTableId
WHERE DataFieldValueDomainId = 10095 AND vt.VirtualTableName = 'DynWater_R'


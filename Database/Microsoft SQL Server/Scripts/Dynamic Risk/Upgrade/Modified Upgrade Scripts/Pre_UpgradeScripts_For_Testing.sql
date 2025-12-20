-------------------------------------------- CM_IRASV6_STAGE
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Datum')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Datum' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Coordinate Projection')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Coordinate Projection' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Datum')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Datum' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Soil Drainage')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Soil Drainage' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'ACVG Survey Type')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'ACVG Survey Type' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'ACVG Survey Equipment')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'ACVG Survey Equipment' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'ACVG Survey Contractor')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'ACVG Survey Contractor' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'ACVG Reading Severity Classification')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'ACVG Reading Severity Classification' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'ACVG Reading Current Direction')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'ACVG Reading Current Direction' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'OF Hurricane Ranking')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'OF Hurricane Ranking' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'ACVG Reading Coating Resistance')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'ACVG Reading Coating Resistance' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'FROST AREA RANGE')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'FROST AREA RANGE' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'ACVG Reading Coating Conductance')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'ACVG Reading Coating Conductance' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'ACVG Severity Type')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'ACVG Severity Type' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'ACVG Anomoly Indication Type')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'ACVG Anomoly Indication Type' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'OF Flood Ranking')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'OF Flood Ranking' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Incident Status')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Incident Status' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Facility Flow Product Type')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Facility Flow Product Type' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Right of Way Owner')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Right of Way Owner' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'OF Flood Ranking')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'OF Flood Ranking' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Pipe Subtype')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Pipe Subtype' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Fabrication Manufacturing Type')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Fabrication Manufacturing Type' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'OF Seismic Ranking')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'OF Seismic Ranking' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Distribution Service Head Susceptibility')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Distribution Service Head Susceptibility' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Distribution Population Density')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Distribution Population Density' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Tank Type')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Tank Type' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Distribution Service Head Susceptibility')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Distribution Service Head Susceptibility' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Incident Status')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Incident Status' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Incident Severity')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Incident Severity' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Secondary Pipe Material')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Secondary Pipe Material' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Primary Pipe Material')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Primary Pipe Material' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Primary Coating')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Primary Coating' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'PressureClass')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'PressureClass' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Distribution Population Density')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Distribution Population Density' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Affected Part')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Affected Part' FROM DomainCatalog          END

INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Vendor' FROM DomainCatalog          
INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Facility Flow Component' FROM DomainCatalog          


		INSERT INTO DomainCatalogColXRef (tablename, columnname, domaincatalogid)
		select 'FacilityFlowGroupComponent', 'FacilityFlowComponentDomainId', id
		from domaincatalog where domaindescr like 'Facility%Flow%Component%'

		INSERT INTO DomainCatalogColXRef (tablename, columnname, domaincatalogid)
		select 'ScheduledInspection', 'VendorDomainId', id
		from domaincatalog where domaindescr like 'Vendor%'	

IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'EC Joint Coating Condition')          BEGIN          
INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'EC Joint Coating Condition' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Internal Lining')          BEGIN          
INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Internal Lining' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Offshore Activity')          BEGIN          
INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Offshore Activity' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'OF Sinkhole')          BEGIN          
INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'OF Sinkhole' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'SCC High SME')          BEGIN          
INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'SCC High SME' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'SCC Near Neutral SME')          BEGIN          
INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'SCC Near Neutral SME' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Storm Damage RM')          BEGIN          
INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Storm Damage RM' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Water Depth')          BEGIN          
INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Water Depth' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Water Movement RM')          BEGIN          
INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Water Movement RM' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'MD MAOP Increase')          BEGIN          
INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'MD MAOP Increase' FROM DomainCatalog          END

		INSERT INTO DomainCatalogColXRef (tablename, columnname, domaincatalogid)
		select 'ECJointCoatingCndition', 'ECJointCoatingCndition', Id
		from domaincatalog where domaindescr like '%EC Joint Coating Condition%'
		INSERT INTO DomainCatalogColXRef (tablename, columnname, domaincatalogid)
		select 'InternalLining', 'InternalLining', Id
		from domaincatalog where domaindescr like '%Internal%Lining%'
		INSERT INTO DomainCatalogColXRef (tablename, columnname, domaincatalogid)
		select 'OffshoreActivity', 'OffshoreActivity', Id
		from domaincatalog where domaindescr like '%Offshore%Activity%'
				INSERT INTO DomainCatalogColXRef (tablename, columnname, domaincatalogid)
		select 'OFSinkhole', 'OFSinkhole', Id
		from domaincatalog where domaindescr like '%OF%Sinkhole%'
		INSERT INTO DomainCatalogColXRef (tablename, columnname, domaincatalogid)
		select 'SCCHighSME', 'SCCHighSME', Id
		from domaincatalog where domaindescr like '%SCC%High%SME%'
				INSERT INTO DomainCatalogColXRef (tablename, columnname, domaincatalogid)
		select 'SCCNearNeutralSME', 'SCCNearNeutralSME', Id
		from domaincatalog where domaindescr like '%SCC%Near%Neutral%SME'
						INSERT INTO DomainCatalogColXRef (tablename, columnname, domaincatalogid)
		select 'StormDamageRM', 'StormDamageRM', Id
		from domaincatalog where domaindescr like '%Storm%Damage%'
							INSERT INTO DomainCatalogColXRef (tablename, columnname, domaincatalogid)
		select 'WaterDepth', 'WaterDepth', Id
		from domaincatalog where domaindescr like '%Water%Depth%'
		INSERT INTO DomainCatalogColXRef (tablename, columnname, domaincatalogid)
		select 'WaterMovementRM', 'WaterMovementRM', Id
		from domaincatalog where domaindescr like '%Water%Movement%'
		INSERT INTO DomainCatalogColXRef (tablename, columnname, domaincatalogid)
		select 'WaterMovementRM', 'WaterMovementRM', Id
		from domaincatalog where domaindescr like '%Water%Movement%'
		INSERT INTO DomainCatalogColXRef (tablename, columnname, domaincatalogid)
		select 'MDMAOPIncrease', 'MDMAOPIncrease', Id
		from domaincatalog where domaindescr like '%MD%MAOP%Increase%'
------------------------------------------USE CM_IRASV6_LINK
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Datum')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Datum' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Coordinate Projection')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Coordinate Projection' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Datum')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Datum' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Soil Drainage')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Soil Drainage' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'ACVG Survey Type')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'ACVG Survey Type' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'ACVG Survey Equipment')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'ACVG Survey Equipment' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'ACVG Survey Contractor')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'ACVG Survey Contractor' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'ACVG Reading Severity Classification')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'ACVG Reading Severity Classification' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'ACVG Reading Current Direction')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'ACVG Reading Current Direction' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'OF Hurricane Ranking')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'OF Hurricane Ranking' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'ACVG Reading Coating Resistance')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'ACVG Reading Coating Resistance' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'FROST AREA RANGE')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'FROST AREA RANGE' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'ACVG Reading Coating Conductance')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'ACVG Reading Coating Conductance' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'ACVG Severity Type')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'ACVG Severity Type' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'ACVG Anomoly Indication Type')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'ACVG Anomoly Indication Type' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'OF Flood Ranking')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'OF Flood Ranking' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Incident Status')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Incident Status' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Facility Flow Product Type')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Facility Flow Product Type' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Right of Way Owner')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Right of Way Owner' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'OF Flood Ranking')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'OF Flood Ranking' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Pipe Subtype')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Pipe Subtype' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Fabrication Manufacturing Type')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Fabrication Manufacturing Type' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'OF Seismic Ranking')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'OF Seismic Ranking' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Distribution Service Head Susceptibility')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Distribution Service Head Susceptibility' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Distribution Population Density')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Distribution Population Density' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Tank Type')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Tank Type' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Distribution Service Head Susceptibility')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Distribution Service Head Susceptibility' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Incident Status')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Incident Status' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Incident Severity')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Incident Severity' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Secondary Pipe Material')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Secondary Pipe Material' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Primary Pipe Material')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Primary Pipe Material' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Primary Coating')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Primary Coating' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'PressureClass')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'PressureClass' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Distribution Population Density')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Distribution Population Density' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Affected Part')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Affected Part' FROM DomainCatalog          END

INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Vendor' FROM DomainCatalog          
INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Facility Flow Component' FROM DomainCatalog          


		INSERT INTO DomainCatalogColXRef (tablename, columnname, domaincatalogid)
		select 'FacilityFlowGroupComponent', 'FacilityFlowComponentDomainId', id
		from domaincatalog where domaindescr like 'Facility%Flow%Component%'

		INSERT INTO DomainCatalogColXRef (tablename, columnname, domaincatalogid)
		select 'ScheduledInspection', 'VendorDomainId', id
		from domaincatalog where domaindescr like 'Vendor%'	

IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'EC Joint Coating Condition')          BEGIN          
INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'EC Joint Coating Condition' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Internal Lining')          BEGIN          
INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Internal Lining' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Offshore Activity')          BEGIN          
INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Offshore Activity' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'OF Sinkhole')          BEGIN          
INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'OF Sinkhole' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'SCC High SME')          BEGIN          
INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'SCC High SME' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'SCC Near Neutral SME')          BEGIN          
INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'SCC Near Neutral SME' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Storm Damage RM')          BEGIN          
INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Storm Damage RM' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Water Depth')          BEGIN          
INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Water Depth' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Water Movement RM')          BEGIN          
INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Water Movement RM' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'MD MAOP Increase')          BEGIN          
INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'MD MAOP Increase' FROM DomainCatalog          END

		INSERT INTO DomainCatalogColXRef (tablename, columnname, domaincatalogid)
		select 'ECJointCoatingCndition', 'ECJointCoatingCndition', Id
		from domaincatalog where domaindescr like '%EC Joint Coating Condition%'
		INSERT INTO DomainCatalogColXRef (tablename, columnname, domaincatalogid)
		select 'InternalLining', 'InternalLining', Id
		from domaincatalog where domaindescr like '%Internal%Lining%'
		INSERT INTO DomainCatalogColXRef (tablename, columnname, domaincatalogid)
		select 'OffshoreActivity', 'OffshoreActivity', Id
		from domaincatalog where domaindescr like '%Offshore%Activity%'
				INSERT INTO DomainCatalogColXRef (tablename, columnname, domaincatalogid)
		select 'OFSinkhole', 'OFSinkhole', Id
		from domaincatalog where domaindescr like '%OF%Sinkhole%'
		INSERT INTO DomainCatalogColXRef (tablename, columnname, domaincatalogid)
		select 'SCCHighSME', 'SCCHighSME', Id
		from domaincatalog where domaindescr like '%SCC%High%SME%'
				INSERT INTO DomainCatalogColXRef (tablename, columnname, domaincatalogid)
		select 'SCCNearNeutralSME', 'SCCNearNeutralSME', Id
		from domaincatalog where domaindescr like '%SCC%Near%Neutral%SME'
						INSERT INTO DomainCatalogColXRef (tablename, columnname, domaincatalogid)
		select 'StormDamageRM', 'StormDamageRM', Id
		from domaincatalog where domaindescr like '%Storm%Damage%'
							INSERT INTO DomainCatalogColXRef (tablename, columnname, domaincatalogid)
		select 'WaterDepth', 'WaterDepth', Id
		from domaincatalog where domaindescr like '%Water%Depth%'
		INSERT INTO DomainCatalogColXRef (tablename, columnname, domaincatalogid)
		select 'WaterMovementRM', 'WaterMovementRM', Id
		from domaincatalog where domaindescr like '%Water%Movement%'
		INSERT INTO DomainCatalogColXRef (tablename, columnname, domaincatalogid)
		select 'WaterMovementRM', 'WaterMovementRM', Id
		from domaincatalog where domaindescr like '%Water%Movement%'
		INSERT INTO DomainCatalogColXRef (tablename, columnname, domaincatalogid)
		select 'MDMAOPIncrease', 'MDMAOPIncrease', Id
		from domaincatalog where domaindescr like '%MD%MAOP%Increase%'

-------------------------------------- AU_IRASV6_STAGE
UPDATE DomainCatalogColXRef SET DomainCatalogId = 116 WHERE TableName = 'DynWater_R' and columnName = 'DynWater_R'
UPDATE DomainCatalogColXRef SET DomainCatalogId = 116 WHERE TableName = 'FaultLine_R' and columnName = 'FaultLine_R'


INSERT INTO DomainCatalog (Id, DomainDescr) SELECT MAX(Id) + 1, 'Soil Other' FROM DomainCatalog 
INSERT INTO DomainCatalog (Id, DomainDescr) SELECT MAX(Id) + 1, 'Coating Condition' FROM DomainCatalog 
INSERT INTO DomainCatalog (Id, DomainDescr) SELECT MAX(Id) + 1, 'Coupon Data' FROM DomainCatalog 
INSERT INTO DomainCatalog (Id, DomainDescr) SELECT MAX(Id) + 1, 'Soil Corrosivity' FROM DomainCatalog 
WHERE NOT EXISTS (SELECT * FROM DomainCatalog where DomainDescr = 'Soil Corrosivity')
INSERT INTO DomainCatalog (Id, DomainDescr) SELECT MAX(Id) + 1, 'Soil Rock Shapes' FROM DomainCatalog 
WHERE NOT EXISTS (SELECT * FROM DomainCatalog where DomainDescr = 'Soil Rock Shapes')
INSERT INTO DomainCatalog (Id, DomainDescr) SELECT MAX(Id) + 1, 'Soil Shrink Swell' FROM DomainCatalog 
WHERE NOT EXISTS (SELECT * FROM DomainCatalog where DomainDescr = 'Soil Shrink Swell')
INSERT INTO DomainCatalog (Id, DomainDescr) SELECT MAX(Id) + 1, 'Soil Texture' FROM DomainCatalog 
WHERE NOT EXISTS (SELECT * FROM DomainCatalog where DomainDescr = 'Soil Texture')

INSERT INTO DomainCatalogColXref (TableName, ColumnName, DomainCatalogId) 
SELECT 'SoilOther', 'SoilOther', Id FROM DomainCatalog 
WHERE  DomainDescr = 'Soil Other'

INSERT INTO DomainCatalogColXref (TableName, ColumnName, DomainCatalogId) 
SELECT 'CoatingCondition', 'CoatingCondition', Id FROM DomainCatalog 
WHERE  DomainDescr = 'Coating Condition Found'
INSERT INTO DomainCatalogColXref (TableName, ColumnName, DomainCatalogId) 
SELECT 'InternalCondition', 'InternalCondition', Id FROM DomainCatalog 
WHERE  DomainDescr = 'Internal Condition'
INSERT INTO DomainCatalogColXref (TableName, ColumnName, DomainCatalogId) 
SELECT 'CouponData', 'CouponData', Id FROM DomainCatalog 
WHERE  DomainDescr = 'Coupon Data'
INSERT INTO DomainCatalogColXref (TableName, ColumnName, DomainCatalogId) 
SELECT 'CasingDescription', 'CasingDescription', Id FROM DomainCatalog 
WHERE  DomainDescr = 'Casing Description'

INSERT INTO DomainCatalogColXref (TableName, ColumnName, DomainCatalogId) 
SELECT 'SoilsCorrosivity', 'SoilsCorrosivity', Id FROM DomainCatalog 
WHERE  DomainDescr = 'Soil Corrosivity'
INSERT INTO DomainCatalogColXref (TableName, ColumnName, DomainCatalogId) 
SELECT 'SoilsRockShapes', 'SoilsRockShapes', Id FROM DomainCatalog 
WHERE  DomainDescr = 'Soil Rock Shapes'
INSERT INTO DomainCatalogColXref (TableName, ColumnName, DomainCatalogId) 
SELECT 'SoilsShrinkSwell', 'SoilsShrinkSwell', Id FROM DomainCatalog 
WHERE  DomainDescr = 'Soil Shrink Swell'
INSERT INTO DomainCatalogColXref (TableName, ColumnName, DomainCatalogId) 
SELECT 'SoilsTexture', 'SoilsTexture', Id FROM DomainCatalog 
WHERE  DomainDescr = 'Soil Texture'

IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Distribution Service Head Susceptibility')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Distribution Service Head Susceptibility' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Tank Type')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Tank Type' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'PressureClass')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'PressureClass' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Distribution Population Density')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Distribution Population Density' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Datum')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Datum' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Coordinate Projection')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Coordinate Projection' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Datum')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Datum' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Casing Inhibitor')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Casing Inhibitor' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'ACVG Survey Type')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'ACVG Survey Type' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'ACVG Survey Equipment')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'ACVG Survey Equipment' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'ACVG Survey Contractor')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'ACVG Survey Contractor' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'ACVG Reading Severity Classification')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'ACVG Reading Severity Classification' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'ACVG Reading Current Direction')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'ACVG Reading Current Direction' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'OF Hurricane Ranking')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'OF Hurricane Ranking' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'ACVG Reading Coating Resistance')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'ACVG Reading Coating Resistance' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'FROST AREA RANGE')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'FROST AREA RANGE' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'ACVG Reading Coating Conductance')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'ACVG Reading Coating Conductance' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'FAULT AREA SLIP SENSE')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'FAULT AREA SLIP SENSE' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'ACVG Severity Type')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'ACVG Severity Type' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Fault Area Slip Rate')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Fault Area Slip Rate' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'ACVG Anomoly Indication Type')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'ACVG Anomoly Indication Type' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'FAULT AREA DIP DIRECTION')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'FAULT AREA DIP DIRECTION' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'OF Flood Ranking')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'OF Flood Ranking' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Right of Way Type')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Right of Way Type' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Facility Flow Product Type')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Facility Flow Product Type' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Right of Way Owner')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Right of Way Owner' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'OF Flood Ranking')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'OF Flood Ranking' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Pipe Subtype')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Pipe Subtype' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Fabrication Manufacturing Type')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Fabrication Manufacturing Type' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'OF Seismic Ranking')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'OF Seismic Ranking' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Distribution Service Head Susceptibility')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Distribution Service Head Susceptibility' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Distribution Population Density')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Distribution Population Density' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'DCVG Survey Type')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'DCVG Survey Type' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'DCVG Anomaly Severity')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'DCVG Anomaly Severity' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'DCVG Anomaly Indication')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'DCVG Anomaly Indication' FROM DomainCatalog          END

INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Facility Flow Component' FROM DomainCatalog          


		INSERT INTO DomainCatalogColXRef (tablename, columnname, domaincatalogid)
		select 'FacilityFlowGroupComponent', 'FacilityFlowComponentDomainId', id
		from domaincatalog where domaindescr like 'Facility%Flow%Component%'

---------------------------------- IRQ_IRASV6_STAGE
ALTER DATABASE IRQ_IRASv6_STAGE SET SINGLE_USER WITH ROLLBACK IMMEDIATE
ALTER DATABASE IRQ_IRASv6_STAGE SET READ_WRITE
ALTER DATABASE IRQ_IRASv6_STAGE SET MULTI_USER

IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'PressureClass')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'PressureClass' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Distribution Population Density')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Distribution Population Density' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Datum')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Datum' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Coordinate Projection')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Coordinate Projection' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Datum')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Datum' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'ACVG Survey Type')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'ACVG Survey Type' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'ACVG Survey Equipment')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'ACVG Survey Equipment' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'ACVG Survey Contractor')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'ACVG Survey Contractor' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'ACVG Reading Severity Classification')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'ACVG Reading Severity Classification' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'ACVG Reading Current Direction')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'ACVG Reading Current Direction' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'OF Hurricane Ranking')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'OF Hurricane Ranking' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'ACVG Reading Coating Resistance')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'ACVG Reading Coating Resistance' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'FROST AREA RANGE')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'FROST AREA RANGE' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'ACVG Reading Coating Conductance')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'ACVG Reading Coating Conductance' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'ACVG Severity Type')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'ACVG Severity Type' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'ACVG Anomoly Indication Type')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'ACVG Anomoly Indication Type' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'OF Flood Ranking')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'OF Flood Ranking' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Right of Way Type')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Right of Way Type' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Facility Flow Product Type')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Facility Flow Product Type' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Right of Way Owner')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Right of Way Owner' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'OF Flood Ranking')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'OF Flood Ranking' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Pipe Subtype')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Pipe Subtype' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Fabrication Manufacturing Type')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Fabrication Manufacturing Type' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'OF Seismic Ranking')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'OF Seismic Ranking' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Distribution Service Head Susceptibility')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Distribution Service Head Susceptibility' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Distribution Population Density')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Distribution Population Density' FROM DomainCatalog          END


IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Facility Flow Component')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Distribution Service Head Susceptibility' FROM DomainCatalog          END
BEGIN
	INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Facility Flow Component' 
	FROM DomainCatalog    
END

INSERT INTO DomainCatalogColXRef (tablename, columnname, domaincatalogid)
select 'FacilityFlowGroupComponent', 'FacilityFlowComponentDomainId', id
from domaincatalog where domaindescr like 'Facility%Flow%Component%'

INSERT INTO DomainCatalog (Id, DomainDescr)
SELECT MAX(Id) + 1, 'Soil Resistivity'
FROM DomainCatalog

INSERT INTO DomainCatalog (Id, DomainDescr)
SELECT MAX(Id) + 1, 'Soil MacroEnvironment'
FROM DomainCatalog

INSERT INTO DomainCatalog (Id, DomainDescr) 
SELECT MAX(Id) + 1, 'TPD Adjacent Buried Utility'
FROM DomainCatalog

INSERT INTO DomainCatalogColXRef (TableName, ColumnName, DomainCatalogId)
SELECT 'ECSoilResistivity', 'ECSoilResistivity', Id FROM DomainCatalog where DomainDescr = 'Soil Resistivity'
GO
--INSERT INTO DomainCatalogColXRef (TableName, ColumnName, DomainCatalogId)
--SELECT 'ECSoilType', 'ECSoilType', Id FROM DomainCatalog where DomainDescr = 'Soil Type'
INSERT INTO DomainCatalogColXRef (TableName, ColumnName, DomainCatalogId)
SELECT 'ECSoilMacroEnvironment', 'ECSoilMacroEnvironment', Id FROM DomainCatalog where DomainDescr LIKE 'Soil MacroEnvironment'
GO
INSERT INTO DomainCatalogColXRef (TableName, ColumnName, DomainCatalogId)
SELECT 'SCCNNHistory', 'SCCNNHistory', Id FROM DomainCatalog where DomainDescr = 'SCCNHistory'
GO
INSERT INTO DomainCatalogColXRef (TableName, ColumnName, DomainCatalogId)
SELECT 'SCCHHistory', 'SCCHHistory', Id FROM DomainCatalog where DomainDescr = 'SCCHHistory'
GO
INSERT INTO DomainCatalogColXRef (TableName, ColumnName, DomainCatalogId)
SELECT 'TPDAdjacentBuriedUtility', 'TPDAdjacentBuriedUtility', Id FROM DomainCatalog where DomainDescr like 'TPD%Adjacent%Buried%Utility'
GO
--INSERT INTO DomainCatalogColXRef (TableName, ColumnName, DomainCatalogId)
--SELECT 'StormDamageRM', 'StormDamageRM', Id FROM DomainCatalog where DomainDescr = 'OF Offshore Storm Damage Remediation'
INSERT INTO DomainCatalogColXRef (TableName, ColumnName, DomainCatalogId)
SELECT 'CoatingConditionFoundDomainID', 'CoatingConditionFoundDomainID', Id FROM DomainCatalog where DomainDescr = 'Coating Condition Found'
GO

------------------------- IRQ_IRASV6_LINK

IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Distribution Population Density')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Distribution Population Density' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Datum')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Datum' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Coordinate Projection')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Coordinate Projection' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Datum')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Datum' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'ACVG Survey Type')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'ACVG Survey Type' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'ACVG Survey Equipment')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'ACVG Survey Equipment' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'ACVG Survey Contractor')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'ACVG Survey Contractor' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'OF Hurricane Ranking')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'OF Hurricane Ranking' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'ACVG Reading Severity Classification')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'ACVG Reading Severity Classification' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'FROST AREA RANGE')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'FROST AREA RANGE' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'ACVG Reading Current Direction')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'ACVG Reading Current Direction' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'ACVG Reading Coating Resistance')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'ACVG Reading Coating Resistance' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'ACVG Reading Coating Conductance')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'ACVG Reading Coating Conductance' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'ACVG Severity Type')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'ACVG Severity Type' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'OF Flood Ranking')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'OF Flood Ranking' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'ACVG Anomoly Indication Type')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'ACVG Anomoly Indication Type' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Facility Flow Product Type')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Facility Flow Product Type' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Right of Way Type')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Right of Way Type' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Right of Way Owner')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Right of Way Owner' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'OF Flood Ranking')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'OF Flood Ranking' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Pipe Subtype')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Pipe Subtype' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Fabrication Manufacturing Type')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Fabrication Manufacturing Type' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'OF Seismic Ranking')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'OF Seismic Ranking' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Distribution Service Head Susceptibility')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Distribution Service Head Susceptibility' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Distribution Population Density')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Distribution Population Density' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Distribution Service Head Susceptibility')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Distribution Service Head Susceptibility' FROM DomainCatalog          END
IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'PressureClass')          BEGIN          INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'PressureClass' FROM DomainCatalog          END

IF NOT EXISTS (SELECT * FROM DomainCatalog WHERE DomainDescr = 'Facility Flow Component')            
begin
	INSERT INTO DomainCatalog(Id, DomainDescr) SELECT MAX(Id) + 1,'Facility Flow Component' 
	FROM DomainCatalog    
end


INSERT INTO DomainCatalogColXRef (tablename, columnname, domaincatalogid)
select 'FacilityFlowGroupComponent', 'FacilityFlowComponentDomainId', id
from domaincatalog where domaindescr like 'Facility%Flow%Component%'


INSERT INTO DomainCatalog (Id, DomainDescr)
SELECT MAX(Id) + 1, 'Transition Description'
FROM DomainCatalog

INSERT INTO DomainCatalog (Id, DomainDescr)
SELECT MAX(Id) + 1, 'Soil Resistivity'
FROM DomainCatalog

INSERT INTO DomainCatalog (Id, DomainDescr)
SELECT MAX(Id) + 1, 'Soil MacroEnvironment'
FROM DomainCatalog

INSERT INTO DomainCatalog (Id, DomainDescr)
SELECT MAX(Id) + 1, 'Prox_Downstream_PS'
FROM DomainCatalog
				
INSERT INTO DomainCatalog (Id, DomainDescr) 
SELECT MAX(Id) + 1, 'TPD Adjacent Buried Utility'
FROM DomainCatalog

INSERT INTO DomainCatalogColXRef (TableName, ColumnName, DomainCatalogId)
SELECT 'Prox_Downstream_PS', 'Prox_Downstream_PS', Id FROM DomainCatalog where DomainDescr = 'Prox_Downstream_PS'
INSERT INTO DomainCatalogColXRef (TableName, ColumnName, DomainCatalogId)
SELECT 'TransitionDescription', 'TransitionDescription', Id FROM DomainCatalog where DomainDescr = 'Transition Description'
INSERT INTO DomainCatalogColXRef (TableName, ColumnName, DomainCatalogId)
SELECT 'ECSoilResistivity', 'ECSoilResistivity', Id FROM DomainCatalog where DomainDescr = 'Soil Resistivity'
INSERT INTO DomainCatalogColXRef (TableName, ColumnName, DomainCatalogId)
SELECT 'ECSoilType', 'ECSoilType', Id FROM DomainCatalog where DomainDescr = 'Soil Type'
INSERT INTO DomainCatalogColXRef (TableName, ColumnName, DomainCatalogId)
SELECT 'ECSoilMacroEnvironment', 'ECSoilMacroEnvironment', Id FROM DomainCatalog where DomainDescr LIKE 'Soil MacroEnvironment'
INSERT INTO DomainCatalogColXRef (TableName, ColumnName, DomainCatalogId)
SELECT 'SCCNNHistory', 'SCCNNHistory', Id FROM DomainCatalog where DomainDescr = 'SCCNHistory'
INSERT INTO DomainCatalogColXRef (TableName, ColumnName, DomainCatalogId)
SELECT 'SCCHHistory', 'SCCHHistory', Id FROM DomainCatalog where DomainDescr = 'SCCHHistory'
INSERT INTO DomainCatalogColXRef (TableName, ColumnName, DomainCatalogId)
SELECT 'TPDAdjacentBuriedUtility', 'TPDAdjacentBuriedUtility', Id FROM DomainCatalog where DomainDescr like 'TPD%Adjacent%Buried%Utility'
INSERT INTO DomainCatalogColXRef (TableName, ColumnName, DomainCatalogId)
SELECT 'StormDamageRM', 'StormDamageRM', Id FROM DomainCatalog where DomainDescr = 'OF Offshore Storm Damage Remediation'
INSERT INTO DomainCatalogColXRef (TableName, ColumnName, DomainCatalogId)
SELECT 'CoatingConditionFoundDomainID', 'CoatingConditionFoundDomainID', Id FROM DomainCatalog where DomainDescr = 'Coating Condition Found'

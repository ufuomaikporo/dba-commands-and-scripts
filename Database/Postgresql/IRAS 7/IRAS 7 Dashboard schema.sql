CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE entity (
    id UUID PRIMARY KEY,
    entity VARCHAR(200) NOT NULL,
	entityType CHAR(4) NOT NULL,
	typedesc VARCHAR(400) NOT NULL,
    code VARCHAR(10) NOT NULL
);

CREATE TABLE entitygroup (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	entityId UUID,
	entityGroupId UUID,
);

CREATE TABLE crackrate (
    entityid UUID NOT NULL REFERENCES client(id),
    inspectionyear NUMERIC(5, 0) NOT NULL,
    rate NUMERIC(12, 6) NOT NULL,
    PRIMARY KEY (clientid, inspectionyear)
);

CREATE TABLE corrosionrate (
    clientid UUID NOT NULL REFERENCES client(id),
    inspectionyear NUMERIC(5, 0) NOT NULL,
    rate NUMERIC(12, 6) NOT NULL,
    PRIMARY KEY (clientid, inspectionyear)
);

CREATE TABLE ncdrate (
    entityid UUID NOT NULL REFERENCES client(id),
    inspectionyear NUMERIC(5, 0) NOT NULL,
    rate NUMERIC(12, 6) NOT NULL,
    PRIMARY KEY (clientid, inspectionyear)
);

CREATE TABLE dashboard (
    id UUID PRIMARY KEY,
    dashboard VARCHAR(200) NOT NULL
);

CREATE TABLE dashboardcontent (
    id UUID NOT NULL REFERENCES dashboard(id),
    entityid UUID NOT NULL REFERENCES client(id),
    title VARCHAR(200) NOT NULL,
    content TEXT,
    PRIMARY KEY (dashboardid, clientid, title)
);
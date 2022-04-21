CREATE TABLE prop (
	id SERIAL NOT NULL PRIMARY KEY,
 
	name  VARCHAR(64) NOT NULL UNIQUE,
	type  VARCHAR(64) NOT NULL DEFAULT 'PROP',
	
	mtime TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
	ctime TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()

) WITHOUT OIDS;

GRANT SELECT,INSERT,UPDATE,DELETE ON prop TO appuser;
GRANT ALL ON prop_id_seq TO appuser;

/* Standard Properties */
INSERT INTO prop (name) VALUES('Datacenter');
INSERT INTO prop (name) VALUES('Vendor');
INSERT INTO prop (name) VALUES('Model');
INSERT INTO prop (name) VALUES('OS Version');
INSERT INTO prop (name) VALUES('OS Vendor');
INSERT INTO prop (name) VALUES('Rack');
INSERT INTO prop (name) VALUES('Height');
INSERT INTO prop (name) VALUES('Tier');
INSERT INTO prop (name) VALUES('Environment');
INSERT INTO prop (name) VALUES('Rack-Position');

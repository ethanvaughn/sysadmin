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
INSERT INTO property (name VALUES('Datacenter');
INSERT INTO property (name VALUES('Vendor');
INSERT INTO property (name) VALUES('Model');
INSERT INTO property (name) VALUES('OS Version');
INSERT INTO property (name) VALUES('OS Vendor');
INSERT INTO property (name) VALUES('Rack');
INSERT INTO property (name) VALUES('Height');
INSERT INTO property (name) VALUES('Tier');
INSERT INTO property (name) VALUES('Environment');
INSERT INTO property (name) VALUES('Rack-Position');

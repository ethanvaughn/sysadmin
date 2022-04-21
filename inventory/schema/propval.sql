CREATE TABLE propval (
	id SERIAL NOT NULL PRIMARY KEY,
 
	prop_id BIGINT NOT NULL REFERENCES prop(id)
		ON UPDATE CASCADE
        ON DELETE CASCADE
        DEFERRABLE,  
	
	value  VARCHAR(64) NOT NULL,
	
	mtime TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
	ctime TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),

	UNIQUE (prop_id,value)
) WITHOUT OIDS;

GRANT SELECT,INSERT,UPDATE,DELETE ON propval TO appuser;
GRANT ALL ON propval_id_seq TO appuser;

/* Standard Property Values */
/*INSERT INTO property (name, type) VALUES('Datacenter', 'PROP');

INSERT INTO property (name, type) VALUES('Vendor', 'PROP');

INSERT INTO property (name, value) VALUES('Vendor', 'HP');
INSERT INTO property (name, value) VALUES('Vendor', 'Dell');
INSERT INTO property (name, value) VALUES('Vendor', 'NetApp');
INSERT INTO property (name, value) VALUES('Vendor', 'Cisco Systems');

INSERT INTO property (name, value) VALUES('Model', 'SunFire X2100');
INSERT INTO property (name, value) VALUES('Model', 'SunFire X4100');
INSERT INTO property (name, value) VALUES('Model', 'SunFire V40z');
INSERT INTO property (name, value) VALUES('Model', 'SunFire V240');
INSERT INTO property (name, value) VALUES('Model', 'SunFire V210');
INSERT INTO property (name, value) VALUES('Model', 'xSeries 345');
INSERT INTO property (name, value) VALUES('Model', 'PowerEdge 2850');
INSERT INTO property (name, value) VALUES('Model', 'CSS 11500');
INSERT INTO property (name, value) VALUES('Model', 'VPN 3000 Concentrator');
INSERT INTO property (name, value) VALUES('Model', 'IDS-4215');
INSERT INTO property (name, value) VALUES('Model', '2600');
INSERT INTO property (name, value) VALUES('Model', '1800');
INSERT INTO property (name, value) VALUES('Model', 'R200');
INSERT INTO property (name, value) VALUES('Model', 'FAS 3020');
INSERT INTO property (name, value) VALUES('Model', 'FAS 3020c');
INSERT INTO property (name, value) VALUES('Model', 'FAS 250');
INSERT INTO property (name, value) VALUES('Model', 'FAS 270');

INSERT INTO property (name, value) VALUES('OS Version', 'RHEL 2.1');
INSERT INTO property (name, value) VALUES('OS Version', 'RHEL 3.4');
INSERT INTO property (name, value) VALUES('OS Version', 'RHEL 3.7');
INSERT INTO property (name, value) VALUES('OS Version', 'RHEL 4.2');
INSERT INTO property (name, value) VALUES('OS Version', 'RHEL 4.4');
INSERT INTO property (name, value) VALUES('OS Version', 'Solaris 8');
INSERT INTO property (name, value) VALUES('OS Version', 'Solaris 9');
	
INSERT INTO property (name, value) VALUES('OS Vendor', 'RedHat');
INSERT INTO property (name, value) VALUES('OS Vendor', 'Sun');

INSERT INTO property (name, value) VALUES('Rack', 'G25');
INSERT INTO property (name, value) VALUES('Rack', 'G26');
INSERT INTO property (name, value) VALUES('Rack', 'G27');
INSERT INTO property (name, value) VALUES('Rack', 'G28');
INSERT INTO property (name, value) VALUES('Rack', 'G29');
INSERT INTO property (name, value) VALUES('Rack', 'G30');
INSERT INTO property (name, value) VALUES('Rack', 'G31');
INSERT INTO property (name, value) VALUES('Rack', 'G32');
INSERT INTO property (name, value) VALUES('Rack', 'G33');
INSERT INTO property (name, value) VALUES('Rack', 'G34');
INSERT INTO property (name, value) VALUES('Rack', 'G35');
INSERT INTO property (name, value) VALUES('Rack', 'G36');
INSERT INTO property (name, value) VALUES('Rack', 'G37');
INSERT INTO property (name, value) VALUES('Rack', 'L25');
INSERT INTO property (name, value) VALUES('Rack', 'L26');
INSERT INTO property (name, value) VALUES('Rack', 'L27');
INSERT INTO property (name, value) VALUES('Rack', 'L28');
INSERT INTO property (name, value) VALUES('Rack', 'L29');
INSERT INTO property (name, value) VALUES('Rack', 'L30');
INSERT INTO property (name, value) VALUES('Rack', 'L31');
INSERT INTO property (name, value) VALUES('Rack', 'L32');
INSERT INTO property (name, value) VALUES('Rack', 'L33');
INSERT INTO property (name, value) VALUES('Rack', 'L34');
INSERT INTO property (name, value) VALUES('Rack', 'L35');
INSERT INTO property (name, value) VALUES('Rack', 'L36');
INSERT INTO property (name, value) VALUES('Rack', 'L37');

INSERT INTO property (name, value) VALUES('Rack', 'AP07');
INSERT INTO property (name, value) VALUES('Rack', 'AQ07');
INSERT INTO property (name, value) VALUES('Rack', 'AR07');
INSERT INTO property (name, value) VALUES('Rack', 'AS07');
INSERT INTO property (name, value) VALUES('Rack', 'AT07');
INSERT INTO property (name, value) VALUES('Rack', 'AU07');
INSERT INTO property (name, value) VALUES('Rack', 'AV07');

INSERT INTO property (name, value) VALUES('Height', '1u');
INSERT INTO property (name, value) VALUES('Height', '2u');
INSERT INTO property (name, value) VALUES('Height', '3u');
INSERT INTO property (name, value) VALUES('Height', '4u');
INSERT INTO property (name, value) VALUES('Height', '5u');

INSERT INTO property (name, value) VALUES('Tier', 'App');
INSERT INTO property (name, value) VALUES('Tier', 'DB');
INSERT INTO property (name, value) VALUES('Tier', 'POS');

INSERT INTO property (name, value) VALUES('Environment', 'MGMT');
INSERT INTO property (name, value) VALUES('Environment', 'DEV');
INSERT INTO property (name, value) VALUES('Environment', 'PREPROD');
INSERT INTO property (name, value) VALUES('Environment', 'PROD');
INSERT INTO property (name, value) VALUES('Environment', 'TEST');
	
INSERT INTO property (name, value) VALUES('Rack-Position', 'U01');
INSERT INTO property (name, value) VALUES('Rack-Position', 'U02');
INSERT INTO property (name, value) VALUES('Rack-Position', 'U03');
INSERT INTO property (name, value) VALUES('Rack-Position', 'U04');
INSERT INTO property (name, value) VALUES('Rack-Position', 'U05');
INSERT INTO property (name, value) VALUES('Rack-Position', 'U06');
INSERT INTO property (name, value) VALUES('Rack-Position', 'U07');
INSERT INTO property (name, value) VALUES('Rack-Position', 'U08');
INSERT INTO property (name, value) VALUES('Rack-Position', 'U09');
INSERT INTO property (name, value) VALUES('Rack-Position', 'U10');
INSERT INTO property (name, value) VALUES('Rack-Position', 'U11');
INSERT INTO property (name, value) VALUES('Rack-Position', 'U12');
INSERT INTO property (name, value) VALUES('Rack-Position', 'U13');
INSERT INTO property (name, value) VALUES('Rack-Position', 'U14');
INSERT INTO property (name, value) VALUES('Rack-Position', 'U15');
INSERT INTO property (name, value) VALUES('Rack-Position', 'U16');
INSERT INTO property (name, value) VALUES('Rack-Position', 'U17');
INSERT INTO property (name, value) VALUES('Rack-Position', 'U18');
INSERT INTO property (name, value) VALUES('Rack-Position', 'U19');
INSERT INTO property (name, value) VALUES('Rack-Position', 'U20');
INSERT INTO property (name, value) VALUES('Rack-Position', 'U21');
INSERT INTO property (name, value) VALUES('Rack-Position', 'U22');
INSERT INTO property (name, value) VALUES('Rack-Position', 'U23');
INSERT INTO property (name, value) VALUES('Rack-Position', 'U24');
INSERT INTO property (name, value) VALUES('Rack-Position', 'U25');
INSERT INTO property (name, value) VALUES('Rack-Position', 'U26');
INSERT INTO property (name, value) VALUES('Rack-Position', 'U27');
INSERT INTO property (name, value) VALUES('Rack-Position', 'U28');
INSERT INTO property (name, value) VALUES('Rack-Position', 'U29');
INSERT INTO property (name, value) VALUES('Rack-Position', 'U30');
INSERT INTO property (name, value) VALUES('Rack-Position', 'U31');
INSERT INTO property (name, value) VALUES('Rack-Position', 'U32');
INSERT INTO property (name, value) VALUES('Rack-Position', 'U33');
INSERT INTO property (name, value) VALUES('Rack-Position', 'U34');
INSERT INTO property (name, value) VALUES('Rack-Position', 'U35');
INSERT INTO property (name, value) VALUES('Rack-Position', 'U36');
INSERT INTO property (name, value) VALUES('Rack-Position', 'U37');
INSERT INTO property (name, value) VALUES('Rack-Position', 'U38');
INSERT INTO property (name, value) VALUES('Rack-Position', 'U39');
INSERT INTO property (name, value) VALUES('Rack-Position', 'U40');
INSERT INTO property (name, value) VALUES('Rack-Position', 'U41');
INSERT INTO property (name, value) VALUES('Rack-Position', 'U42');
INSERT INTO property (name, value) VALUES('Rack-Position', 'U43');
INSERT INTO property (name, value) VALUES('Rack-Position', 'U44');
INSERT INTO property (name, value) VALUES('Rack-Position', 'U45');
*/
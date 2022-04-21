CREATE TABLE device_bak AS SELECT * FROM device;

CREATE TABLE item AS SELECT * FROM device;
CREATE SEQUENCE item_id_seq;
SELECT setval( 'item_id_seq', max(id) ) FROM item;
ALTER TABLE item ADD PRIMARY KEY (id);
ALTER TABLE item ALTER COLUMN id SET DEFAULT nextval('item_id_seq'::regclass);
ALTER TABLE item ALTER COLUMN id SET NOT NULL;
GRANT SELECT,INSERT,UPDATE,DELETE ON item TO appuser;
GRANT ALL ON item_id_seq TO appuser;

ALTER TABLE ipaddr RENAME COLUMN device_id TO item_id;
ALTER TABLE ipaddr DROP CONSTRAINT "$1";
ALTER TABLE ipaddr ADD CONSTRAINT itemfk FOREIGN KEY (item_id) REFERENCES item(id)
	ON UPDATE CASCADE
	ON DELETE CASCADE
	DEFERRABLE;

ALTER TABLE attribval RENAME COLUMN device_id TO item_id;
ALTER TABLE attribval DROP CONSTRAINT "attribval_device_id_fkey";
ALTER TABLE attribval ADD CONSTRAINT itemfk FOREIGN KEY (item_id) REFERENCES item(id)
	ON UPDATE CASCADE
	ON DELETE CASCADE
	DEFERRABLE;

ALTER TABLE ownerlink RENAME COLUMN device_id TO item_id;
ALTER TABLE ownerlink DROP CONSTRAINT "$1";
ALTER TABLE ownerlink ADD CONSTRAINT itemfk FOREIGN KEY (item_id) REFERENCES item(id)
	ON UPDATE CASCADE
	ON DELETE CASCADE
	DEFERRABLE;

ALTER TABLE userlink RENAME COLUMN device_id TO item_id;
ALTER TABLE userlink DROP CONSTRAINT "$1";
ALTER TABLE userlink ADD CONSTRAINT itemfk FOREIGN KEY (item_id) REFERENCES item(id)
	ON UPDATE CASCADE
	ON DELETE CASCADE
	DEFERRABLE;

ALTER TABLE propdevicelink RENAME COLUMN device_id TO item_id;
ALTER TABLE propdevicelink DROP CONSTRAINT "propdevicelink_device_id_fkey";
ALTER TABLE propdevicelink ADD CONSTRAINT itemfk FOREIGN KEY (item_id) REFERENCES item(id)
	ON UPDATE CASCADE
	ON DELETE CASCADE
	DEFERRABLE;

DROP TABLE device;

ALTER TABLE propdevicelink RENAME TO propitemlink;


/* Later .... 
ALTER TABLE item DROP COLUMN hostname
DROP COLUMN serialnum
DROP COLUMN auth_check
*/


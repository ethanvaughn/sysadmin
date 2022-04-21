CREATE TABLE item (
	id SERIAL NOT NULL PRIMARY KEY,

	itemname    VARCHAR(128) NOT NULL UNIQUE,
	serialno    VARCHAR(128),
	comment     VARCHAR(128),
	auth_check  TIMESTAMP WITHOUT TIME ZONE DEFAULT NULL,
	admin_notes TEXT,
	notes       TEXT,
	template_id BIGINT NOT NULL REFERENCES template(id)
		ON UPDATE CASCADE
		ON DELETE CASCADE
		DEFERRABLE,
		
	mtime TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
	ctime TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()

) WITHOUT OIDS;

ALTER SEQUENCE item_id_seq RESTART WITH 100000;

GRANT SELECT,INSERT,UPDATE,DELETE ON item TO appuser;
GRANT ALL ON item_id_seq TO appuser;
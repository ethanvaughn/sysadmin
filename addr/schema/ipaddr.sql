CREATE TABLE ipaddr (
	id SERIAL NOT NULL PRIMARY KEY,

	ipaddr    BIGINT NOT NULL,
	adminip   BOOLEAN DEFAULT 'FALSE',
	comment   VARCHAR(256),
	item_id   BIGINT REFERENCES item(id)
		ON UPDATE CASCADE
        ON DELETE CASCADE
        DEFERRABLE,
	subnet_id BIGINT REFERENCES subnet(id)
		ON UPDATE CASCADE
        ON DELETE CASCADE
        DEFERRABLE,

	mtime TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
	ctime TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()

) WITHOUT OIDS;


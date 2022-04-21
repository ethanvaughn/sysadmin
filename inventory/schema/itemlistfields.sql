CREATE TABLE itemlistfields (

	template_id  BIGINT NOT NULL REFERENCES template(id)
		ON UPDATE CASCADE
        ON DELETE CASCADE
        DEFERRABLE,

	field_name  VARCHAR(128),
	field_order VARCHAR(4)

) WITHOUT OIDS;

GRANT SELECT,INSERT,UPDATE,DELETE ON itemlistfields TO appuser;

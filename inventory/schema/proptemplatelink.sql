CREATE TABLE proptemplatelink (

	prop_id BIGINT NOT NULL REFERENCES prop(id)
		ON UPDATE CASCADE
        ON DELETE CASCADE
        DEFERRABLE,
	template_id BIGINT NOT NULL REFERENCES template(id)
		ON UPDATE CASCADE
        ON DELETE CASCADE
        DEFERRABLE,

	PRIMARY KEY (prop_id, template_id)
) WITHOUT OIDS;

GRANT SELECT,INSERT,UPDATE,DELETE ON proptemplatelink TO appuser;

/*
	NOTE: this is a link table between "template" and "company" tables. 
	A record in this table defines which templates use the "users" field.
*/
CREATE TABLE usertemplatelink (

	template_id  BIGINT NOT NULL REFERENCES template(id)
		ON UPDATE CASCADE
        ON DELETE CASCADE
        DEFERRABLE

) WITHOUT OIDS;

GRANT SELECT,INSERT,UPDATE,DELETE ON usertemplatelink TO appuser;

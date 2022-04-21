/*
	NOTE: this is a link table between "item" and "company" tables. 
	Any single item will have at most one owner.
*/
CREATE TABLE ownerlink (

	item_id  BIGINT NOT NULL REFERENCES item(id)
		ON UPDATE CASCADE
        ON DELETE CASCADE
        DEFERRABLE, 
	company_id BIGINT NOT NULL REFERENCES company(id)
		ON UPDATE CASCADE
        ON DELETE CASCADE
        DEFERRABLE

) WITHOUT OIDS;

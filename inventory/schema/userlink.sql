/*
	NOTE: this is a link table between "item" and "company" tables. 
	Many companies can use any single item.
*/
CREATE TABLE userlink (

	item_id  BIGINT NOT NULL REFERENCES item(id)
		ON UPDATE CASCADE
        ON DELETE CASCADE
        DEFERRABLE, 
		
	company_id BIGINT NOT NULL REFERENCES company(id) 
		ON UPDATE CASCADE
        ON DELETE CASCADE
        DEFERRABLE

) WITHOUT OIDS;

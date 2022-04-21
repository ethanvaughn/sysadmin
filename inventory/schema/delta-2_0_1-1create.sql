/* template.sql */
/* prop.sql */
/* propval.sql */
/* proptemplatelink.sql */
/* propdevicelink.sql */
/* attribval.sql */
ALTER TABLE device ADD COLUMN template_id 
	BIGINT REFERENCES template(id)
	ON UPDATE CASCADE
	ON DELETE CASCADE
	DEFERRABLE;

update device set template_id=1;
alter table device alter column template_id set default 1;
alter table device alter column template_id set not null;

ALTER TABLE device ADD COLUMN template_id 
	BIGINT REFERENCES template(id)
	ON UPDATE CASCADE
	ON DELETE CASCADE
	DEFERRABLE;

update device set template_id=1;
alter table device alter column template_id set default 1;
alter table device alter column template_id set not null;



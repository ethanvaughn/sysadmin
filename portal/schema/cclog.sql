CREATE TABLE cclog (
	id SERIAL NOT NULL PRIMARY KEY,

	time         timestamp WITHOUT TIME ZONE NOT NULL,
	state        VARCHAR(20) NOT NULL,
	sys_name     VARCHAR(64),
	machine_name VARCHAR(64),
	schema_name  VARCHAR(64),
	instance     VARCHAR(64),
	user_name    VARCHAR(64),
	program_id   VARCHAR(64),
	card_id      VARCHAR(64),
	table_name   VARCHAR(64),
	pk_data      VARCHAR(64),
	msg          VARCHAR(256),

	ctime timestamp WITHOUT TIME ZONE NOT NULL DEFAULT 'now',
	mtime timestamp WITHOUT TIME ZONE NOT NULL DEFAULT 'now'

) WITHOUT OIDS;

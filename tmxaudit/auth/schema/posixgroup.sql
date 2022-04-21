CREATE TABLE posixgroup (
	id SERIAL NOT NULL PRIMARY KEY,

	gid BIGINT NOT NULL UNIQUE,
	name VARCHAR(128) NOT NULL UNIQUE,

    ctime timestamp WITHOUT TIME ZONE NOT NULL DEFAULT 'now',
    mtime timestamp WITHOUT TIME ZONE NOT NULL DEFAULT 'now'

) WITHOUT OIDS;


/* User Groups */
INSERT INTO posixgroup (gid,name) VALUES ('40000','sysadmin');
INSERT INTO posixgroup (gid,name) VALUES ('40002','netuser');

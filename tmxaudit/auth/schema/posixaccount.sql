CREATE TABLE posixaccount (
	id SERIAL NOT NULL PRIMARY KEY,

	uid BIGINT NOT NULL UNIQUE,
	/*gid BIGINT NOT NULL REFERENCES posixgroup(gid),*/
	gid BIGINT NOT NULL,
	username VARCHAR(128) NOT NULL UNIQUE,
	shell VARCHAR(128) NOT NULL DEFAULT '/bin/bash',
	homedir VARCHAR(128) NOT NULL DEFAULT '/u01/home/dba',
	gecos VARCHAR(256),
	md5_passwd VARCHAR(128),
	sh_lastchange BIGINT DEFAULT 13175,
	sh_min INT DEFAULT 0,
	sh_max INT DEFAULT 99999,
	sh_warn INT DEFAULT 7,
	sh_inact INT,
	sh_expire INT,

    ctime timestamp WITHOUT TIME ZONE NOT NULL DEFAULT 'now',
    mtime timestamp WITHOUT TIME ZONE NOT NULL DEFAULT 'now',

	CONSTRAINT person_username UNIQUE (username)
) WITHOUT OIDS;


CREATE TABLE passhist (
	id SERIAL NOT NULL PRIMARY KEY,

	username BIGINT NOT NULL REFERENCES posixaccount(username),
	md5_passwd VARCHAR(128),

    ctime timestamp WITHOUT TIME ZONE NOT NULL DEFAULT 'now',
    mtime timestamp WITHOUT TIME ZONE NOT NULL DEFAULT 'now'

) WITHOUT OIDS;

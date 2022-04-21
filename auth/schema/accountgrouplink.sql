CREATE TABLE accountgrouplink (

	accountname varchar(128) NOT NULL REFERENCES posixaccount(username)
			ON UPDATE CASCADE
			ON DELETE CASCADE
			DEFERRABLE,
	groupname varchar(128) NOT NULL REFERENCES posixgroup(name)
			ON UPDATE CASCADE
			ON DELETE CASCADE
			DEFERRABLE,

    ctime timestamp WITHOUT TIME ZONE NOT NULL DEFAULT 'now',
    mtime timestamp WITHOUT TIME ZONE NOT NULL DEFAULT 'now',

	CONSTRAINT accountgrouplink_pk PRIMARY KEY(accountname,groupname)
) WITHOUT OIDS;

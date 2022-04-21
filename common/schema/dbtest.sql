CREATE TABLE dbtest (
	id SERIAL NOT NULL PRIMARY KEY,

	uid BIGINT NOT NULL UNIQUE,
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

	/* 
		Since the mtime field is defined first, it will be set to "NOW()"
		on UPDATE:
	
		The ctime field should only be set during INSERT and not change
		on UPDATE. For example:

			INSERT INTO dbtest (uid,username,ctime) 
				VALUES(40000, 'jrandom', NOW());

			update dbtest set homedir='hithere';

		The sequence above will set both ctime and mtime to NOW() during 
		INSERT, but only mtime will be affected on UPDATE.
	*/
	mtime timestamp,
	ctime timestamp, 

	CONSTRAINT person_username UNIQUE (username)
);


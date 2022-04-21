CREATE TABLE company (
	id SERIAL NOT NULL PRIMARY KEY,

	name VARCHAR(128) NOT NULL UNIQUE,
	code VARCHAR(64)  NOT NULL UNIQUE,
	
	mtime TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
	ctime TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()

) WITHOUT OIDS;

INSERT INTO company (name, code) VALUES ('Tomax Corp.', 'TMX');
INSERT INTO company (name, code) VALUES ('Mud Bay', 'MB');
INSERT INTO company (name, code) VALUES ('Air Terminal Gifts', 'ATG');
INSERT INTO company (name, code) VALUES ('Sutton Place Gourmet', 'SPG');
INSERT INTO company (name, code) VALUES ('Snyders Drug Stores', 'SDS');
INSERT INTO company (name, code) VALUES ('Benjamin Moore Paints', 'BMP');
INSERT INTO company (name, code) VALUES ('Ratner Companies', 'RAT');
INSERT INTO company (name, code) VALUES ('Duckwall - Alco', 'DW');
INSERT INTO company (name, code) VALUES ('Kelly-Moore Paints', 'KMP');
INSERT INTO company (name, code) VALUES ('ADM', 'ADM');
INSERT INTO company (name, code) VALUES ('Andronicos', 'AND');
INSERT INTO company (name, code) VALUES ('EZ Lube', 'EZ');
INSERT INTO company (name, code) VALUES ('Associated Food Stores', 'AFS');
INSERT INTO company (name, code) VALUES ('The Andersons, Inc.', 'ADR');


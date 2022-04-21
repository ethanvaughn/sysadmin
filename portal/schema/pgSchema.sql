CREATE TABLE hosts (
	hostname varchar(10) PRIMARY KEY,
	site varchar(10),
	status int2,
	plugin_output varchar(10)
);

CREATE TABLE customers (
	customer varchar(10) PRIMARY KEY
);

CREATE TABLE memberships (
	customer varchar(10),
	hostname varchar(10),
	PRIMARY KEY (customer, hostname),
	FOREIGN KEY (customer) REFERENCES customers,
	FOREIGN KEY (hostname) REFERENCES hosts
);

CREATE TABLE services (
	hostname varchar(10) not null,
	service varchar(25),
	status int2,
	statusoutput text,
	PRIMARY KEY (hostname, service),
	FOREIGN KEY (hostname) REFERENCES hosts
);

SELECT m.customer, m.hostname, s.service, s.status, s.statusoutput FROM memberships AS m, services AS s WHERE m.hostname=s.hostname;

SELECT m.customer, m.hostname, h.status, h.plugin_output FROM memberships AS m, hosts AS h WHERE m.hostname=h.hostname;

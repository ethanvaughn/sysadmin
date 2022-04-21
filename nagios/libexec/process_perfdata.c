#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>
#define VERSION "$Id: process_perfdata.c,v 1.1 2008/04/04 00:30:43 jkruse Exp $"

/*
	Purpose:	Takes performance data from Nagios and writes
			it out a file in directory with the format of
			hostname-service_desc.log

	$Id: process_perfdata.c,v 1.1 2008/04/04 00:30:43 jkruse Exp $
	$Date: 2008/04/04 00:30:43 $

*/

char *hostname;
char *service;
char *perfdata;
char *directory;
char *filename;

void usage(char* self) {
	printf("%s - CVS Version Tag:%s\n\n",self,VERSION);
	printf("%s -H <hostname> -S \"<service desc>\" -P \"<perfdata>\" -D <directory>\n",self);
}

void deleteFile() {
	// Don't check the error code: we don't care if this worked or not
	// if a service doesn't return any performance data for multiple checks, this will not work after
	// the first time we delete the file.  That's OK, since there is no if (-e filename) style
	// test that we can do in C
	unlink(filename);
}

void reformatService() {
	int len = strnlen(service,200);		// Get the length of the service description
	int i;
	for (i = 0; i < len; i++) {		// Replace all spaces with underscores
		if (service[i] == ' ') {
			service[i] = '_';
		}
	}
}

void writeFile() {
	FILE *fp;
	fp = fopen(filename,"w+");
	if (fp != 0) {					// check and make sure the file opened OK
		//printf("Opened file: %s\n",filename); // debugging
		fprintf(fp,"%s",perfdata);		// Write it out to the file
		fclose(fp);				// And close it
		// Now change permissions on the file
		//if (chmod(filename,(S_IRWXU | S_IRWXG | S_IRWXO)) == 0) {
		// this changes the permissions to 0666 - see docs for what these constants are
		if (chmod(filename,((S_IRUSR | S_IWUSR) | (S_IRGRP | S_IWGRP) | (S_IROTH | S_IWOTH))) == 0) {
			return;
		} else {
			printf("Unable to change permissions for %s\n",filename);
		}
	} else {
		printf("Unable to write to %s\n",filename);
		return;
	}
}

void buildFilename() {
	asprintf(&filename,"%s%s-%s.log",directory,hostname,service);
}

int validateArgs(int argc, char **argv) {
	int argcount = 0;
	opterr = 0;
	int c;
	while ((c = getopt (argc,argv,"H:S:D:P:")) != -1) {
		switch(c) {
			case 'H':
				hostname = optarg;
				argcount++;
				break;
			case 'S':
				service = optarg;
				argcount++;
				break;
			case 'D':
				directory = optarg;
				argcount++;
				break;
			case 'P':
				perfdata = optarg;
				argcount++;
				break;
			case '?':
				if (isprint(optopt)) {
					fprintf(stderr,"Unknown option `-%c'.\n", optopt);
				} else {
					fprintf(stderr,"Unknown option character `\\x%x'.\n",optopt);
				}
			default:
				abort();
		}
	}
	return argcount;
}

int main (int argc, char **argv) {
	// validateArgs will return the number of arguments that were passed in (4 == good)
	if (validateArgs(argc,argv) == 4) {
		reformatService();	// Replaces all of the spaces in the service name with underscores
		buildFilename();	// assembles directory,hostname, and service desc into a full filname
		deleteFile();		// Delete the file if it exists
		// Before doing anything, check and see if this service check returned any performance
		// data.  Plenty of them do not return anything, such as process running checks, tablespace
		// checks, URL checks, etc.  For all of these, exit if strnlen(perfdata,200) == 0.  Note
		// the use of strnlen to prevent any possible buffer overflow condition.  Maybe
		// it doesn't matter, but better safe than sorry
		if (strnlen(perfdata,200) != 0) {
			writeFile();		// Writes the perfdata into the above-generated filename
		} 
	} else {
		usage(argv[0]);
	}
	return 0;
}

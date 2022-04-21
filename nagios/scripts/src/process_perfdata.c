#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>

char *hostname;
char *service;
char *perfdata;
char *directory;
char filename[150];

void usage() {
	printf("process_perfdata -H <hostname> -S \"<service desc>\" -P \"<perfdata>\" -D <directory>\n");
}

void reformatService() {
	int len = strlen(service);
	int i;
	for (i = 0; i < len; i++) {
		if (service[i] == ' ') {
			service[i] = '_';
		}
		// Truncate at the '[' char:
		if (service[i] == '[') {
			if (service[i-1] == '_') {
				// Trailing underscore; remove it.
				i = i - 1;
			}
			service[i] = '\0';
			break;
		}
	}
}

void writeFile() {
	// first need to make sure we have something to write...
	if (strlen(perfdata) == 0) {
		return;
	}
	FILE *fp;
	fp = fopen(filename,"w+");
	// check and make sure the file opened OK
	if (fp != 0) {
		//printf("Opened file: %s\n",filename); // debugging
		// Write it out to the file
		fprintf(fp,"%s",perfdata);
		// Now write the status (w/o \n)
		fclose(fp);
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
	strcat( filename, directory );

	// Handle the trailing slash in the directory:
	int lastchar = ( strlen( directory ) - 1);
	if (directory[lastchar] != '/') {
		strcat( filename, "/" );
	}

	strcat(filename,hostname);
	strcat(filename,"-");
	strcat(filename,service);
	strcat(filename,".log");
}

int validateArgs(int argc, char **argv) {
	int argcount = 0;
	opterr = 0;
	int c;
	// get command-line arguments
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
		// incoming arguments validated.  Now reformat the service name
		reformatService();
		// build the filename now
		buildFilename();
		// write the data to the file
		writeFile();
	} else {
		usage();
	}
	return 0;
}

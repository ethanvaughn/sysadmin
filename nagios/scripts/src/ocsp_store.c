#include <unistd.h>
#include <stdio.h>
#include <string.h>

char *hostname;
char *service;
char *service_output;
char *state_type;
char *directory;
char filename[150];
int stateid;

void usage() {
	printf("Usage: ocsp_store\n");
	printf("\t-H <hostname>\n");
	printf("\t-S <service description>\n");
	printf("\t-D <directory>\n");
	printf("\t-O <service output (quoted)>\n");
	printf("\t-T <HARD|SOFT>\n");
	printf("\t-I <0|1|2|3>\n");
}

void reformatService() {
	int len = strlen(service);
	int i;
	for (i = 0; i < len; i++) {
		if (service[i] == ' ') {
			service[i] = '_';
		}
	}
}

void writeFile() {
	FILE *fp;
	fp = fopen(filename,"w+");
	// check and make sure the file opened OK
	if (fp != 0) {
		//printf("Opened file: %s\n",filename); // debugging
		// Write it all out at once
		fprintf(fp,"%s\n",service_output);
		// Now write the status (w/o \n)
		fprintf(fp,"%d",stateid);
		fclose(fp);
	} else {
		printf("Unable to write to %s\n",filename);
		return;
	}
}

void buildFilename() {
	strcat(filename,directory);
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
	while ((c = getopt (argc,argv,"H:S:D:I:O:T:")) != -1) {
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
			case 'O':
				service_output = optarg;
				argcount++;
				break;
			case 'T':
				state_type = optarg;
				argcount++;
				break;
			case 'I':
				stateid = atoi(optarg);
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
	// validateArgs will return the number of arguments that were passed in (6 == good)
	if (validateArgs(argc,argv) == 6) {
		// only take action on hard states
		if (strcmp(state_type,"HARD") == 0) {
			// incoming arguments validated.  Now reformat the service name
			reformatService();
			// build the filename now
			buildFilename();
			// write the data to the file
			writeFile();
		} else {
			return 0;
		}
	} else {
		// tell the user what they should have done
		usage();	
	}
}

#include <unistd.h>
#include <stdio.h>
#define FILENAME_SIZE 200
#define OUTPUT_SIZE 200
#define VERSION "$Id: get_generic_value.c,v 1.6 2008/08/12 17:03:38 jkruse Exp $"

/*

 Purpose:	Reads Nagios performance data files.  Prints the contents
		of the file specified and deletes it (unless -k is specified) afterwards.
		Input files are of the following:
		<base directory>/<hostname>-<service name>.log
		For example:
		/u01/app/cacti/nagios_perfdata/wdc-nagios-CPU_Usage.log
		would be read from the following syntax:
		-H wdc-nagios -S -CPU_Usage.log -D /u01/app/cacti/nagios_perfdata

 $Id: get_generic_value.c,v 1.6 2008/08/12 17:03:38 jkruse Exp $
 $Date: 2008/08/12 17:03:38 $

*/

char *hostname;
char *suffix;
char *directory;
char filename[FILENAME_SIZE];
int keep;

// deleteFile(): deletes the performance file that has just been read
void deleteFile() {
	if (unlink(filename) != 0) {
		perror("Unlinking");
	}
}

// usage(char* self): 
void usage(char* self) {
	fprintf(stderr,"%s - CVS Version Tag:%s\n\n",self,VERSION);
	fprintf(stderr,"Usage: %s -H <hostname> -S <suffix> -D <directory of perf files> (optional) -k\n",self);
}

// buildFilename(): builds the filename to read (combines directory + hostname + suffix)
void buildFilename() {
	// To be safe against buffer overflows, strncat is used instead of strcat.  Note that
	// the filename array is only FILENAME_SIZE characters, so keep that in mind: neither the
	// hostname nor suffix can exceed 50 characters, and the base dir no more than 100 chars
	// (assuming FILENAME_MAX is 200)
	strncat(filename,directory,100);
	strncat(filename,hostname,50);
	strncat(filename,suffix,50);
	// Debugging
	//printf("Filename: %s\n",filename);
}

int validateArgs(int argc, char **argv) {
	int c,valcount;
	valcount = 0;
	opterr = 0;
	keep = 0;
	// get command-line arguments
	// note that k is optional (used to specify whether or not we keep
	// the file or not)
	while ((c = getopt (argc,argv,"H:S:D:k")) != -1) {
		switch(c) {
			case 'H':
				hostname = optarg;
				valcount++;
				break;
			case 'S':
				suffix = optarg;
				valcount++;
				break;
			case 'D':
				directory = optarg;
				valcount++;
				break;
			case 'k':
				keep = 1;
				break;
			case '?':
				if (isprint(optopt)) {
					fprintf(stderr,"Unknown option `-%c'.\n", optopt);
				} else {
					fprintf(stderr,"Unknown option character `\\x%x'.\n",optopt);
				}
				return 3;
			default:
				abort();
		}
	}
	return valcount;
}


// char* readFile(): reads in the file and returns a ptr to the string containing the perf data, and null otherwise
char* readFile () {
	FILE *fp;
	char* output = malloc((sizeof(char))*OUTPUT_SIZE); // allocate OUTPUT_SIZE chars for the perf data
	fp = fopen(filename,"r"); // open file read-only
	int c;
	int i = 0;
	if (fp != 0) {
		// copy the contents of the file into output.  Again, have
		// to make sure we do not exceed the size of our buffer,
		// read no more than OUTPUT_SIZE characters
		while((c = fgetc(fp)) != EOF && i < OUTPUT_SIZE) {
			output[i] = c;
			i++;
		}
		fclose(fp);
		return output;
	} else {
		return NULL;
	}
}

int main (int argc, char **argv) {
	// first check incoming arguments
	if (validateArgs(argc,argv) == 3) {
		buildFilename(); // now build the filename to read from
		char *output = readFile(); // and read it
		if (output != NULL) { // readFile() returns null if it can't read the file
			printf("%s",output);
			if (keep == 0) {
				deleteFile(); // only delete the file IF we were able to read successfully
			} 
		} else {
			fprintf(stderr,"Unable to open %s\n",filename);
		}
		free(output); // let go of the memory allocated (not necessary, but best practice)
	} else {
		usage(argv[0]);
	}
	return 0;
}

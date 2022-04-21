#include <unistd.h>
#include <stdio.h>

char *hostname;
char *suffix;
char *directory;
char filename[150];

// deleteFile(): deletes the performance file that has just been read
void deleteFile() {
	if (unlink(filename) != 0) {
		perror("Unlinking");
	}
}

// usage(): 
void usage(char *self) {
	printf("Usage: %s -H <hostname> -S <suffix> -D <directory of perf files>\n",self);
}

// buildFilename(): builds the filename to read (combines directory + hostname + suffix)
void buildFilename() {
	strcat(filename,directory);
	strcat(filename,hostname);
	strcat(filename,suffix);
	// Debugging
	//printf("Filename: %s\n",filename);
}

int validateArgs(int argc, char **argv) {
	int c,valcount;
	valcount = 0;
	opterr = 0;
	// get command-line arguments
	while ((c = getopt (argc,argv,"H:S:D:")) != -1) {
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


// char* readFile(): reads in the file and returns a ptr to the string containing the perf data,
//			and null otherwise
char* readFile () {
	FILE *fp;
	char* output = malloc((sizeof(char))*150); // allocate 150 chars for the perf data
	fp = fopen(filename,"r"); // open file read-only
	int c;
	int i = 0;
	if (fp != 0) {
		// copy the contents of the file into output
		while((c = fgetc(fp)) != EOF) {
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
			printf("%s\n",output);
			deleteFile(); // only delete the file IF we were able to read successfully
		} else {
			printf("Unable to open %s\n",filename);
		}
		free(output); // let go of the memory allocated
	} else {
		usage(argv[0]);
	}
	return 0;
}

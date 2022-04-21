#include <unistd.h>
#include <stdio.h>
#include <string.h>

char *hostname;
char *suffix;
char *directory;
char filename[150];

// deleteFile(): deletes the performance file that has just been read
void deleteFile() {
	if (unlink(filename) != 0) {
		printf("Error on %s\n",filename);
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
	char* input = malloc((sizeof(char))*150); // allocate 150 chars for the input str
	char* output = malloc((sizeof(char))*150); // allocate 150 chars for output str
	fp = fopen(filename,"r"); // open file read-only
	int i = 0, j = 0;
	char delim = ' ';
	if (fp != 0) {
		int c;
		// copy the contents of the file into input
		while((c = fgetc(fp)) != EOF) {
			input[i] = c;
			i++;
		}
		fclose(fp);
		// now split this sucker up
		char *token = strtok(input,&delim);
		for (i = 0; i < strlen(token); i++) {
			if (token[i] == '=') {
				token[i] = ':';
			}
			if (token[i] == ';') {
				token[i] = '\0'; // this terminates the string
				break;
			}
		}
		strcat(output,token);
		strcat(output," ");
		// last_token is used here since token will eventually get set to null by strtok.  To prevent that,
		// we use another char ptr that is set to token's ptr on each iteration except when token is set
		// to null, in which case last_token = the last ptr token pointed at (the last value of the string)
		char *last_token; 
		while((token = strtok(NULL,&delim)) != NULL) {
			last_token = token;
			for (i = 0; i < strlen(last_token); i++) {
				if (last_token[i] == '=') {
					last_token[i] = ':';
				}
				if (last_token[i] == ';') {
					last_token[i] = '\0'; // terminate the string same as above
					strcat(output,last_token);
					strcat(output," ");
					break;
				}
					
			}
		}
		free(input); // get rid of the memory we don't need anymore
		return output;
	} else {
		return NULL;
	}
}

int main (int argc, char **argv) {
	// first check incoming arguments
	if (validateArgs(argc,argv) == 3) {
		buildFilename(); // now build the filename to read from
		char* load = readFile(); // and read it
		if (load != NULL) {
			printf("%s",load);
			deleteFile();
		} else {
			printf("Unable to open %s\n",filename);
		}
		free(load);
	} else {
		usage(argv[0]);
	}
	return 0;
}

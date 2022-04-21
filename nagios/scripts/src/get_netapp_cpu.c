#include <unistd.h>
#include <stdio.h>

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


// int readFile(): reads in the file and return CPU usage as an int.  Returns -1 on error
int readFile () {
	FILE *fp;
	int output = -1;
	fp = fopen(filename,"r"); // open file read-only
	char output_str[2];
	int c, flag = -1;
	if (fp != 0) {
		// copy the contents of the file into output
		while((c = fgetc(fp)) != EOF) {
			if (flag >= 0) {
				if (isdigit(c)) {
					output_str[flag] = c;
					flag++;
				}
				if ((char)c == ';') {
					break;
				}
			}
			if ((char)c == '=') {
				flag++;
			}
		}
		fclose(fp);
	} else {
		printf("Unable to open %s\n",filename);
	}
	if (flag != -1) {
		output = atoi(&output_str);
	}
	return output;
}

int main (int argc, char **argv) {
	// first check incoming arguments
	if (validateArgs(argc,argv) == 3) {
		buildFilename(); // now build the filename to read from
		int cpu = readFile(); // and read it
		if (cpu != -1) {
			printf("%d",cpu);
			deleteFile();
		}
	} else {
		usage(argv[0]);
	}
	return 0;
}

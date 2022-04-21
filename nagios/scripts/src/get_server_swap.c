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
void usage(char* self) {
	printf("Usage: get_server_swap -H <hostname> -S <suffix> -D <directory of perf files>\n",self);
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
double readFile () {
	FILE *fp;
	char* output = malloc((sizeof(char))*150); // allocate 150 chars for the perf data
	fp = fopen(filename,"r"); // open file read-only
	int c;
	int i = 0,j = 0;
	const char delim[] = ";";
	double swap_used = -1;
	if (fp != 0) {
		// copy the contents of the file into output
		while((c = fgetc(fp)) != EOF) {
			output[i] = c;
			i++;
		}
		fclose(fp);
		// if swap_available_str isn't malloc'd, it tends to overwrite other strings
		char *swap_available_str = malloc(sizeof(char)*30);
		int swap_available;
		char *token = strtok(output,delim); // get the first token of the string
		// token has the amount of swap available, but the problem is that it has letters in it
		// so iterate the string and just take the numbers
		for (i = 0; i < strlen(token); i++) {
			if (isdigit(token[i])) {
				swap_available_str[j] = token[i];
				j++;
			}
		}
		// now take the string and store it as an int in swap_available
		swap_available = atoi(swap_available_str); // this is how much swap is *available*
		free (swap_available_str); // we are done with this string now
		// call strtok two more times but ignore the output -- we only want the very last token
		// if it's NULL, we know something has gone wrong
		strtok(NULL,delim);
		strtok(NULL,delim);
		strtok(NULL,delim);
		token = strtok(NULL,delim);
		if (token != NULL) {
			int swap_total = atoi(token);
			swap_used = swap_total - swap_available;
			swap_used*= 1048576; // Convert to bytes
			free(output);
		}
	}
	return swap_used;
}

int main (int argc, char **argv) {
	// first check incoming arguments
	if (validateArgs(argc,argv) == 3) {
		buildFilename(); // now build the filename to read from
		double swap = readFile(); // and read it
		if (swap != -1) {
			printf("swap:%.0f\n",swap);
			deleteFile(); // Uncomment when you're sure it works!
		}
	} else {
		usage(argv[0]);
	}
	return 0;
}

#include <unistd.h>
#include <stdio.h>


/** update_passive_service.c: C version of update_passive_service.pl
**/
char *hostname;
char *service;
char *directory;
char filename[150];


// Yes, it was horrible to do all of this in main().  But it works, dangit
int main (int argc, char **argv) {
	hostname = NULL;
	service = NULL;
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
				service = optarg;
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
	if (valcount == 3) {
		int i;
		int len = strlen(service);
		// Replace all spaces with underscores in the service description
		for (i = 0; i < len; i++) {
			if (service[i] == ' ') {
				service[i] = '_';
			}
		}
		// Concatentate hostname-service.log
		// We have the options: now build the filename
		//printf("Options: -H %s -S %s\n",hostname,service);
		strcat(filename,directory);
		strcat(filename,hostname);
		strcat(filename,"-");
		strcat(filename,service);
		strcat(filename,".log");
		//printf("Filename: %s\n",filename); // Debugging
		// Now attempt to open the file
		FILE *fp;
		int status;
		fp = fopen(filename,"r");
		if (fp != 0) {
			//printf("File %s opened OK\n",filename); // Debugging
			//return status;
			int c,status;
			while((c = fgetc(fp)) != EOF) {
				if (c == '\n') {
					break;
				} else {
					unsigned char x = c;
					printf("%c",x);
				}
			}
			// That read the first line
			// Now just do one read to get the exit code
			c = fgetc(fp);
			fclose(fp); // close the file, we're done now
			if (c == EOF) {
				status = 3; // If no exit code was provided, default to UNKNOWN (3)
			} else {
				/** The ASCII value of our exit code is stored in c.  These are as follows
				48: 0
				49: 1
				50: 2
				51: 3
				 **/
				if (c == 48) {
					status = 0;
				} else if (c == 49) {
					status = 1;
				} else if (c == 50) {
					status = 2;
				} else {
					status = 3;
				}
			}
			return status;
		} else {
			//printf("Filename %s not found\n",filename); // Debugging
			printf("Service has not yet been checked\n");
			return 0;
		}
	} else {
		printf("Usage: update_passive_service -H <hostname> -S <service> -D <directory>\n");
		return 3;
	}
}

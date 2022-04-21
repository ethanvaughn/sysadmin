#include <unistd.h>
#include <ctype.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "strrev.h"
#include "getline.h"
#define CHARCOUNT 512

char *ip_address;
int exit_code;
const char *password = "1vilnax9";
const char *bin = "/usr/bin/rsh";

// usage(): 
void usage(char *exe) {
	printf("Usage: %s -H <hostname>\n",exe);
	exit_code = 3;
}

int validateArgs(int argc, char **argv) {
	int c,valcount;
	valcount = 0;
	opterr = 0;
	// get command-line arguments
	while ((c = getopt (argc,argv,"H:")) != -1) {
		switch(c) {
			case 'H':
				ip_address = optarg;
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

void getDiskUtil() {
	char *cmd;
	char *line;
	asprintf(&cmd,"%s %s -l root:%s sysstat -u -c 1 1",bin,ip_address,password);
	FILE *fp = NULL;
	fp = popen(cmd,"r");
	if (fp != NULL) {
		int len,status;
		while ((line = getline(CHARCOUNT)) != NULL) {
			printf("%s",line);
			free(line);
		}
		pclose(fp);
	}
}

int main (int argc, char **argv) {
	exit_code = 3; // Set exit code to unknown
	// first check incoming arguments
	if (validateArgs(argc,argv) == 1) {
		getDiskUtil();
	} else {
		usage(argv[0]);
	}
	exit(exit_code);
}

#include <unistd.h>
#include <ctype.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "strrev.h"

char *ip_address, *self;
int exit_code;
const char *oid = "SNMPv2-SMI::enterprises.1718.3.2.5.1.6.1.1";
const char *bin = "/usr/bin/snmpget";

// usage(): 
void usage() {
	printf("Usage: %s <hostname>\n",self);
	exit_code = 3;
}

int validateArgs(int argc, char **argv) {
	self = argv[0];
	if (argc == 2) {
		ip_address = argv[1];
		return 1;
	}
}


void getTemp() {
	char *cmd;
	char *output = malloc(sizeof(char)*200);
	asprintf(&cmd,"%s -v 1 -c public %s %s 2>&1",bin,ip_address,oid); // build cmd string
	FILE *fp = NULL;
	fp = popen(cmd,"r");
	int c;
	int i = 0;
	if (fp != NULL) {
		// copy the contents of the file into output
		while((c = fgetc(fp)) != EOF && c != '\n' && i < 200) {
			output[i] = c;
			i++;
		}
		exit_code = pclose(fp);
		exit_code >>= 8;
		if (exit_code != 0) {
			printf("Unable to connect to %s\n",ip_address);
			exit_code = 2;
			return;
		} else {
			// snmpget exited OK, which means, hopefully, we have valid input
			int j = strlen(output) - 1;
			i = 0;
			char *temp_str = malloc(sizeof(char)*4); // big enough for temps up to 999 degrees..
			while (isdigit(output[j]) && i < 4) {
				temp_str[i] = output[j];
				j--;
				i++;
			}
			temp_str = strrev(temp_str);
			char *stopper = NULL;
			double temp = (1.8*(strtod(temp_str,&stopper)/10))+32;
			printf("%.2lf",temp);
			exit_code = 0;
			free(temp_str);
		}
	} else {
		printf("Unable to execute %s",cmd);
		exit_code = 2;
	}
	free(cmd);
	free(output);
}

int isNumber(char *str) {
	int len = strlen(str);
	int i;
	int retval = 1;
	for (i = 0; i < len; i++) {
		if (!isdigit(str[i])) {
			retval = 0;
			break;
		}
	}
	return retval;
}

int main (int argc, char **argv) {
	exit_code = 3; // Set exit code to unknown
	// first check incoming arguments
	if (validateArgs(argc,argv) == 1) {
		getTemp();
	} else {
		usage();
	}
	exit(exit_code);
}

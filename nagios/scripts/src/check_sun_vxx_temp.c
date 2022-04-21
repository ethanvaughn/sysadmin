#include <unistd.h>
#include <ctype.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "strrev.h"

char *ip_address;
int warning,critical,exit_code;
const char *oid = "SNMPv2-SMI::enterprises.9237.2.1.1.4.1.1.2.1";
const char *bin = "/usr/bin/snmpget";

// usage(): 
void usage() {
	printf("Usage:  -H <hostname> -w <warning temp> -c <critical temp>\n");
	exit_code = 3;
}

int validateArgs(int argc, char **argv) {
	int c,valcount;
	valcount = 0;
	opterr = 0;
	// get command-line arguments
	while ((c = getopt (argc,argv,"H:w:c:")) != -1) {
		switch(c) {
			case 'H':
				ip_address = optarg;
				valcount++;
				break;
			case 'w':
				if (isNumber(optarg)) {
					warning = atoi(optarg);
					valcount++;
				}
				break;
			case 'c':
				if (isNumber(optarg)) {
					critical = atoi(optarg);
					valcount++;
				}
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
			printf("CRITICAL: %s",output);
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
			if (temp < (double)warning) {
				printf("OK: Ambient Temp %.2lf F|%.2lf",temp,temp);
				exit_code = 0;
			} else if (temp < (double)critical) {
				printf("WARNING: Ambient Temp %.2lf F|%.2lf",temp,temp);
				exit_code = 1;
			} else {
				printf("CRITICAL: Ambient Temp %.2lf F|%.2lf",temp,temp);
				exit_code = 2;
			}
			free(temp_str);
		}
	} else {
		printf("CRITICAL: Unable to execute %s",cmd);
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
	if (validateArgs(argc,argv) == 3) {
		getTemp();
	} else {
		usage();
	}
	exit(exit_code);
}

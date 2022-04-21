#include <unistd.h>
#include <ctype.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "strrev.h"

char *ip_address;
int critical,exit_code;
const char *oid = ".1.3.6.1.4.1.789.1.2.1.3.0";
const char *bin = "/usr/bin/snmpget";

// usage(): 
void usage(char *self) {
	printf("Usage: %s -H <hostname> -c <critical %>\n",self);
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


void getCPU() {
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
			char *cpu_str = malloc(sizeof(char)*3); // big enough for CPU up to 100..
			while (isdigit(output[j]) && i < 3) {
				cpu_str[i] = output[j];
				j--;
				i++;
			}
			cpu_str = strrev(cpu_str);
			char *stopper = NULL;
			long int cpu = strtod(cpu_str,&stopper);
			if (cpu < critical) {
				printf("OK: CPU Usage %d%|%d",cpu,cpu);
				exit_code = 0;
			} else {
				printf("CRITICAL: CPU Usage %d%|%d",cpu,cpu);
				exit_code = 2;
			}
			free(cpu_str);
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
	if (validateArgs(argc,argv) == 2) {
		getCPU();
	} else {
		usage(argv[0]);
	}
	exit(exit_code);
}

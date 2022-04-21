/*
	Purpose:	Check NetApp CPU Usage
			(Mostly a wrapper around snmpget)
	Notes:		Depends on strrev.h, which is
			expected to be in the same directory
			as the source at compile time
	$Id: check_netapp_cpu.c,v 1.1 2008/02/26 01:02:43 jkruse Exp $
	$Date: 2008/02/26 01:02:43 $
*/


#define VERSION "$Id: check_netapp_cpu.c,v 1.1 2008/02/26 01:02:43 jkruse Exp $"
#include <unistd.h>
#include <ctype.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "strrev.h"

char *ip_address;					// IP address to query
int exit_code;						// Exit code to return to Nagios
const int critical = 90;				// Critical threshold
const char *oid = ".1.3.6.1.4.1.789.1.2.1.3.0";		// OID to query
const char *bin = "/usr/bin/snmpget";			// Path to snmpget
const char *community = "public";			// SNMP community version

// usage(): 
void usage(char *self) {
	printf("%s - CVS Version Tag:%s\n\n",self,VERSION);
	printf("Usage: %s -I <hostname / IP address>\n",self);
	exit_code = 3;
}

// validateArgs: returns the number of validated arguments
int validateArgs(int argc, char **argv) {
	int c,valcount;
	valcount = 0;
	opterr = 0;
	// get command-line arguments
	while ((c = getopt (argc,argv,"I:")) != -1) {
		switch(c) {
			case 'I':
				ip_address = optarg;
				valcount++;
				break;
			case '?':
				if (isprint(optopt)) {
					fprintf(stderr,"Unknown option `-%c'.\n", optopt);
				} else {
					fprintf(stderr,"Unknown option character `\\x%x'.\n",optopt);
				}
				return 0;
			default:
				abort();
		}
	}
	return valcount;
}

void getCPU() {
	char *cmd;
	char *output = malloc(sizeof(char)*200);
	asprintf(&cmd,"%s -v 1 -c %s %s %s 2>&1",bin,community,ip_address,oid); // build cmd string
	FILE *fp = NULL;
	/*
		Note that we wely on snmpget's timeouts instead of implementing
		either select/pool or some time of use of the alarm signal.
		As long as snmpget always has an appropriate timeout, it's not necessary
	*/
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
			printf("%s",output);
			exit_code = 2;
			return;
		} else {
			// snmpget exited OK, which means, hopefully, we have valid input
			
			// find the length of the string
			int j = strlen(output) - 1;
			i = 0;
			char *cpu_str = malloc(sizeof(char)*3); // big enough for CPU up to 100..
			// copy all of the digits from the end of the string into cpu_str
			while (isdigit(output[j]) && i < 3) {
				cpu_str[i] = output[j];
				j--;
				i++;
			}
			// now reverse the values, since it was copied in reverse.  This is the CPU Usage
			cpu_str = strrev(cpu_str);
			// Finally, convert cpu_str into an integer we can use
			char *stopper = NULL;
			long int usage = strtod(cpu_str,&stopper);
			// Before moving on, free up cpu_str: we don't need it anymore
			free(cpu_str);
			printf("%d%|%d",usage,usage);
			if (usage < critical) {
				exit_code = 0;
			} else {
				exit_code = 2;
			}
		}
	} else {
		// For some reason (file not found, perhaps) we couldn't
		// run the command.  A better error would be nice here
		printf("Unable to execute %s",cmd);
		exit_code = 3;
	}
	free(cmd);
	free(output);
}

// isNumber: tests to see if a given string contains only numeric values
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
	exit_code = 3; // Set exit code to unknown (the default)
	// first check incoming arguments
	if (validateArgs(argc,argv) == 1) {
		getCPU();
	} else {
		usage(argv[0]);
	}
	exit(exit_code);
}

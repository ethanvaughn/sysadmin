#include <stdio.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
#include <signal.h>
#include "getline.h"
#define CHARCOUNT 1024
#define MAX_COMMANDS 10

int command_count; // the number of commands we have read in
char* commands[MAX_COMMANDS]; // commands read off of stdin go in this aarray
const char* nagios = "/u01/app/nagios/var/rw/nagios.cmd"; // where the Nagios FIFO is located

void abort_read() {
        printf("No data received,exiting\n");
        exit(1);
}

void submitCMDs() {
	time_t t;
	int i;
	FILE *fp;
	// normally we would open something like this in append mode.  But you can't seek to the end
	// of a named pipe, so it can only be opened in write mode.  You can't try to open it for reading either,
	// since it's a named pipe that'll block forever.  Only alternative would be to stat() the file,
	// but this will work for now
	fp = fopen(nagios,"w");
	// make sure it opened properly
	if (fp == NULL) {
		printf("%s could not be opened\n",nagios);
		fclose(fp);
		return;
	}
	// now print out the commands
	for (i = 0; i < command_count; i++) {
		time(&t);
		fprintf(fp,"[%ld] %s\n",t,commands[i]);	
		free(commands[i]);
	}
	fclose(fp);
}

void readInput() {
	char* line;
	const char s1[12] = "CMD: PROCESS";
	int i;
	// getline reads off of stdin, and is a blocking read.  If nothing is read within the number
	// of seconds specified by alarm(int seconds), abort_read() is called, which exits
	signal(SIGALRM,abort_read);
	alarm(5);
	while ((line = getline(CHARCOUNT)) != NULL && command_count < MAX_COMMANDS) {
		// first a safety check -- make sure length of line > 12
		if (strlen(line) < 12) {
			free(line);
			continue; // skip this line if length < 12
		}
		if (strncmp(s1,line,12) == 0) {
			// create a new character array where we will put a subset of line
			// line contains CMD: , (note the space!!!) which we do not want to include in the data
			// passed to submitCMDs().  So a new string is created, which is just a copy of line, minus
			// the first 5 chars
			char* cmd = malloc(sizeof(char)*CHARCOUNT);
			int j;
			for (i = 5,j = 0; i < CHARCOUNT; i++,j++) {
				if (line[i] == '\0') {
					break; // stop at the end of the string..
				} else {
					cmd[j] = line[i];
				}
			}
			// add this string to commands and advance index counter (dumb comment)
			commands[command_count] = cmd;
			command_count++;
		}
		free(line);
	}
	alarm(0);
}

int main() {
	command_count = 0; // initialize command_count
	readInput(); // now read input off of stdin
	submitCMDs(); // and submit all commands to the FIFO
	return 0;
}

#include <sys/sysinfo.h>
#include <stdio.h>

int main() {
	int days, hours, mins;
	struct sysinfo sys_info;

	if(sysinfo(&sys_info) != 0)
		perror("sysinfo");

	days = sys_info.uptime / 86400;
	hours = (sys_info.uptime / 3600) - (days * 24);
	mins = (sys_info.uptime / 60) - (days * 1440) - (hours * 60);
	
	if (sys_info.uptime < 300) {
		printf("CRITICAL: Server restarted - check services");
		return 2;
	} else {
		printf("Uptime: %d days, %d hours, %d minutes, %ld seconds\n",days,hours,mins,sys_info.uptime % 60);
		return 0;
	}
}

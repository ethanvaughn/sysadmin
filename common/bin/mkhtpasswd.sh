#!/bin/bash

CAT=/bin/cat
CUT=/bin/cut
GREP=/bin/grep


htpasswd=/u01/app/common/www/.htpasswd
tmpfile=/tmp/mkht0001

$CAT /etc/passwd | $CUT -d ":" -f 1,4 | $GREP "40001\|40000" | $CUT -d ":" -f1 > $tmpfile

>$htpasswd
for user in $(<$tmpfile); do
	$GREP $user /etc/shadow | $CUT -d ":" -f 1,2 >> $htpasswd
done

exit 0

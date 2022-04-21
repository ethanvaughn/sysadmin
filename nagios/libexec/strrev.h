/*
	Purpose:	Useful function for reversing a string
			in-place without creating an additional
			string
	$Id: strrev.h,v 1.1 2008/02/26 01:02:10 jkruse Exp $
	$Date: 2008/02/26 01:02:10 $
*/


char *strrev(char *str) {
	char *p1, *p2;
	if (! str || ! *str)
		return str;

	for (p1 = str, p2 = str + strlen(str) - 1; p2 > p1; ++p1, --p2) {
		*p1 ^= *p2;
		*p2 ^= *p1;
		*p1 ^= *p2;
	}
	return str;
} 

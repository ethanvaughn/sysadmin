#!/usr/bin/awk -f

BEGIN { nb = 0; }

{
	 if ( $0=="" )
	 {
		nb++;
	 }
	 else
	 {
		   if( nb > 0 )
		   {
				for(i = 0; i < nb; i++) print "";
				nb = 0;
		   }
			print $0;
	 }
}

/*
	Purpose: Wrapper around the GNU Java GetOpt object to provide
	the same functionality as ArgParse.pm	

	$Id: ArgParse.java,v 1.2 2009/08/18 22:11:57 evaughn Exp $
	$Date: 2009/08/18 22:11:57 $
*/

import java.util.*;
import gnu.getopt.Getopt;


public class ArgParse {
	
	private static final String version = "$Id: ArgParse.java,v 1.2 2009/08/18 22:11:57 evaughn Exp $";

	public static void main(String[] args) {
		System.out.println(version);
		System.exit(0);
	}

	private HashMap args;
	private String optstr;
	int validated_args;
	int c;

	private static final int default_timeout = 15;
	
	public ArgParse( String[] cmd_args, char[] chars, String version, String usage ) {
		//Map<char, String> args = new HashMap();
		args = new HashMap();
		optstr = buildOptStr( chars );
		Getopt g = new Getopt( "error", cmd_args, optstr );
		int char_pos = 0;
		char current_opt;
		while ((c = g.getopt()) != -1 && char_pos < chars.length ) {
			current_opt = chars[char_pos];
			if (c == current_opt) {
					String s = g.getOptarg();
					if (s != null) {
						args.put( current_opt, g.getOptarg() );
						validated_args++;
					}
			}
			char_pos++;
		}
		// Set a default timeout
		Integer i;
		if (!args.containsKey('t')) {
			// In this case, the -t was omitted
			i = new Integer(default_timeout);
			args.put('t',i);
			validated_args++;
		} else {
			// In this case, the -t was present
			// Try to convert the timeout to an int prior
			// to storing it in the args hash
			try {
				i = new Integer((String)args.get('t'));
			} catch (Exception e) {
				// If the exception is thrown, set i back to
				// its default value
				i = new Integer(default_timeout);
			}
			args.put('t',i);
				
		}
		// If not all of the required arguments are present, call usage(), which will exit
		if (validated_args != chars.length) {
			usage(version,usage);
		}
	}

	public HashMap args() {
		return args;
	}

	public int argCount() {
		return validated_args;
	}

	private String buildOptStr(char[] chars) {
		StringBuilder s = new StringBuilder();
		for (int i = 0; i < chars.length; i++) {
			s.append(chars[i]);
			s.append(":");
			if (chars[i] == 't') {
				// timeout is optional, which is denoted by a double-colon
				s.append(":");
			}
		}
		return s.toString();
	}

	private void usage(String version,String usage) {
		System.out.println("Usage: " + usage);
		System.out.println("CVS Version Tag: " + version);
		System.exit(3);
	}
}

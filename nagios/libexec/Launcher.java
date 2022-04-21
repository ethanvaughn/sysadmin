import java.io.*;
import java.util.*;

/*

 Purpose:	Service Check load & execute wrapper.  Does the following:
		1) Takes in command-line arguments as described below
		2) Reads in the credentials and SQL associated with the given service
		3) Starts a new thread which executes the given service check class
		4) Watches the thread for completion

 $Id: Launcher.java,v 1.5 2009/10/14 18:29:57 evaughn Exp $
 $Date: 2009/10/14 18:29:57 $

*/

public class Launcher {

	public static final String version = "$Id: Launcher.java,v 1.5 2009/10/14 18:29:57 evaughn Exp $";

	public static String basedir; // base where config files are stored
	public static HashMap<String,String> config; // All thresholds/config directives are stored here

	public static String serviceName;
	public static String className; // needs to be defined below!
	public static String hostName;
	public static String customerCode;
	public static String IP;
	public static int timeout;
	public static String SQL;

	public static void main (String[] args) {
		/*
		 * Command-line arguments are as follows (7 total)
		 * 0) Host name
		 * 1) IP address
		 * 2) Customer Code
		 * 3) Service_Name (must be underscored)
		 * 4) Class_Name (also must be underscored)
		 * 5) Where to go to look for threshold files (base path)
		 * 6) timeout (in seconds)
		 * The rest is provided by the threshold files
		 * that each class will read
		 *
		 * Now a note on arguments 3 and 4:
		 * The service name is just that, say Pending Transactions or Database Throughput, or Foo Bar Blah
		 * The class name is just that; the class that will be responsible for this check
		 **/
		if (args.length != 7 || !validateArgs(args)) {
			usage();
		} else {
			hostName = args[0];
			IP = args[1];
			customerCode = args[2];
			serviceName = args[3];
			className = args[4];
			basedir = args[5];

			try {
				timeout = Integer.parseInt(args[6]);
			} catch (NumberFormatException nfe) {
				System.out.println("Invalid timeout: " + args[6]);
				usage();
			}

			config = new HashMap<String,String>();
			try {
				// What the heck is this for?
				// Each service is its own class, since they all have unique requirements
				// in terms of how they work.  Each class does use the ServiceCheck interface, though.
				// Therefore these two lines allow the class to be instantiated dynamically and cast back to a ServiceCheck
				Class c = Class.forName(className);
				ServiceCheck s = (ServiceCheck)c.newInstance();
				// We were able to instantiate the class, so far so good.  Now
				// need to deal with the credentials files.  There will be at least one file
				// (for the host) and possibly another for the service itself.  Values in the service
				// credentials can override those in the host credential file
				readProperties();
				// Now that the properties have been read, add a few arguments from the command-line
				// that the plugin might need
				// and now read in all of the SQL
				readSQL();

				// What is the Executor class and why is it here?
				// Timeouts on network operations are a pain in the rear in Java.
				// The solution is to do all of the database query stuff in a separate thread

				Executor e = new Executor(s);
				Thread t = new Thread(e);
				t.start();

				// What is the WaitOnExecutor class?
				// This is more because Java sucks.  Threads can't be manipulated or accessed in
				// a static context (which main() is) therefore a separate class is instantiated which
				// will effectively monitor the thread's status

				WaitOnExecutor w = new WaitOnExecutor(e,timeout);
				w.run(); // this is NOT a thread, just a class we're instantiating and running!
			} catch (ClassNotFoundException cnfe) {
				System.out.println(className + " Not Found, Contact SA Team");
				System.exit(3);
			} catch (InstantiationException ie) {
				// Don't know when this error should occur, but we're required to catch it
				System.out.println(ie.getMessage() + ": Contact SA Team");
				System.exit(3);
			} catch (IllegalAccessException iae) {
				// Even less of an idea when this error will occur, same drill as above
				System.out.println(iae.getMessage() + ": Contact SA Team");
				System.exit(3);
			}


		}
	}

	private static void usage() {
		/*
		 * Command-line arguments are as follows (7 total)
		 * 0) Host name
		 * 1) IP address
		 * 2) Customer Code
		 * 3) Service_Name (must be underscored)
		 * 4) Class_Name (also must be underscored)
		 * 5) Where to go to look for threshold files (base path)
		 * 6) Timeout (in seconds)
		 */
		System.out.println("Version: " + version);
		System.out.println("Usage: java Launcher <hostname> <IP> <customer code> Service_Name Class_Name <base directory> <timeout>");
		System.exit(3);
	}

	private static void readProperties() {
//System.out.println( "readProperties" );
		Properties globalProperties = new Properties();
		Properties serviceProperties = new Properties();
		// First try and read in the global properties
		try {
			globalProperties.load( new FileInputStream( basedir + "/" + customerCode + "/" + hostName + ".credentials" ) );
			// If this works, load all of the keys into the config hashmap
			loadProperties( globalProperties );
		} catch (IOException e) {
			// We won't error out yet -- the point is that at least one of these files
			// exists with credentials for us
			//System.out.println("Could not open " + basedir + "/" + customerCode + "/" + hostName + ".credentials");
		}
		// Now load the local properties -- if this file doesn't exist, that's fine.
		// Any values that already existed in the global properties will get overwritten by these
		try {
			serviceProperties.load(new FileInputStream(basedir + "/" + customerCode + "/" + hostName + "-" + serviceName + ".credentials"));
			// Now load these properties into the config hash (overwriting any that already exist)
			loadProperties( serviceProperties );
		} catch (IOException e) {
			// We're just going to ignore this exception
			// for the same reason we ignored it with the first error
		}
		// Now that all of the properties have been read, they need to be validated
		// the following properties are mandatory:
		// username
		// password
		// port
		// sid
		if (config.containsKey("username") && config.containsKey("password") && config.containsKey("port") && config.containsKey("sid")) {
			return;
		} else {
			// If the 4 above fields can't be found in the hash, the script must abort
			System.out.println("username,password,port,and sid are required fields in either host or service .credentials file");
			System.exit(3);
		}

	}

	// loadProperties: takes a properites file and loads all of its key/value pairs into a hash
	// the purpose behind this is this script reads in multiple property files, and this function merges them all
	// into a single configuration hash
	private static void loadProperties(Properties p) {
//System.out.println( "loadProperties" );
		Enumeration e = p.propertyNames();
		while (e.hasMoreElements()) {
			Object o = e.nextElement();
			config.put( (String)o, p.getProperty( (String)o ) ); // HashMaps can only contain strings
		}
	}

	// readSQL: reads in a file containing a SQL query.  Nothing fancy, just reads in a file and returns a string
	private static void readSQL() {
//System.out.println( "readSQL" );
		StringBuilder strbuf = new StringBuilder();
		String filename = basedir + "/" + customerCode + "/" + hostName + "-" + serviceName + ".sql";
		BufferedReader input = null;

		// Test first for the threshold file. If it doesn't exist, set filename to the default.
		try {
			input = new BufferedReader( new FileReader( filename ) );
		} catch (FileNotFoundException fnfe) {
			filename = basedir + "/default/" + serviceName + ".sql";
		} catch (IOException ioe) {
			filename = basedir + "/default/" + serviceName + ".sql";
		} finally {
			try {
				if (input != null) {
					input.close();
				}
			} catch (IOException ioe) {
				System.out.println( "I/O Error on file close, contact SA Team: " + ioe.getMessage() );
				System.exit(3);
			}
		}

		// Now that the correct file has been verified, read it
		try {
			input = new BufferedReader( new FileReader( filename ) );
			String line = null;
			while ((line = input.readLine()) != null) {
				strbuf.append( line );
				strbuf.append( " " );
			}
			if (strbuf.length() == 0) {
				System.out.println( "Empty query in file " + filename );
				System.exit(3);
			} else {
				// The file was read in OK, set global variable SQL to this string
				SQL = strbuf.toString();
				//System.out.println("SQL:" + SQL);
			}
		} catch (FileNotFoundException fnfe) {
			System.out.println( filename + " not found" );
			System.exit(3);
		} catch (IOException ioe) {
			System.out.println( "I/O Error, contact SA Team: " + ioe.getMessage() );
			System.exit(3);
		} finally {
			try {
				if (input != null) {
					input.close();
				}
			} catch (IOException ioe) {
				System.out.println( "I/O Error on file close, contact SA Team: " + ioe.getMessage() );
			}
		}

	}

	// Simple function that tests to make sure all elements of args are defined
	// Very lame test, but oh well
	private static boolean validateArgs(String[] args) {
//System.out.println( "validateArgs" );
		boolean result;
		int valid_count = 0;
		for (int i = 0; i < args.length; i++) {
			if (args[i].length() > 0) {
				valid_count++;
				//System.out.println("Arg: " + i + " length: " + args[i].length() + " (" + args[i] + ")");
			} 
		}
		if (valid_count == args.length) {
			result = true;
		} else {
			result = false;
		}
		return result;
	}

}


import java.io.*;
import java.net.*;
import java.util.*;
import java.util.concurrent.locks.*;

/*
	$Id: CheckRemoteSockets.java,v 1.2 2008/08/16 20:25:08 jkruse Exp $
	$Date: 2008/08/16 20:25:08 $
*/

public class CheckRemoteSockets {

	// Contants - version info, usage examples, and other global directives
	static final String version	= "$Id: CheckRemoteSockets.java,v 1.2 2008/08/16 20:25:08 jkruse Exp $";
	static final String usage	= "java CheckRemoteSockets -I <IP> -C <customer abbrev.> -H <hostname> -S \"Service Name\" -t <optional timeout>";
	static final String basedir	= "/u01/home/nagios/monitoring";
	static final char[] chars	= {'I','C','H','S','t'};

	static HashMap parsed_args;
	static String suffix;
	static String filename;
	static String displayFilename;

	static ArrayList sockets;
	static int timeout;

	static String output;
	static int return_code;

	static HashMap ports = new HashMap();

	public static void main(String[] args) {
		// Call ArgParse and get all the command-line goodness in order
		ArgParse a = new ArgParse(args,chars,version,usage);
		parsed_args = a.args();
		String raw_suffix = (String)parsed_args.get('S');
		suffix = raw_suffix.replaceAll(" ","_");

		// Build the full filename we will open as well as the name that will be used to display
		filename = basedir + "/" + parsed_args.get('C') + "/" + parsed_args.get('H') + "-" + suffix;
		displayFilename = parsed_args.get('C') + "/" + parsed_args.get('H') + "-" + suffix;

		// Validate (and convert back to an integer) the timeout
		parseTimeout();

		// Now load the list of ports and descriptions from the file
		readPortsFromFile();

		// And finally, create and start the threads to check each of the ports
		checkSockets();

		System.out.println(output);	
		System.exit(return_code);
	}

	private static void parseTimeout() {
		Integer i = (Integer)parsed_args.get('t');
		timeout = i.intValue();
	}

	// checkSockets
	private static void checkSockets() {
		// Initialize all variables before using them
		return_code = 0;
		sockets = new ArrayList();

		// Now iterate through all of the ports and create the SocketTest objects
		Set keys = ports.keySet();
		Iterator itr = keys.iterator();
		while (itr.hasNext()) {
			Object description = itr.next();
			int port;
			try {
				port = Integer.parseInt((String)ports.get((String)description));
				SocketTest st = new SocketTest((String)description,(String)parsed_args.get('I'),port);
				sockets.add(st);
			} catch (NumberFormatException nfe) {
				System.out.println("Unreadable: " + (String)ports.get((String)description));
				System.out.println("Invalid port number found in " + displayFilename);
				System.exit(3);
			}
		}
		// Now start all of the newly created objects
		for (int i = 0; i < sockets.size(); i++) {
			SocketTest st = (SocketTest)sockets.get(i);
			Thread t = new Thread(st);
			t.start();
		}

		// All the checks have been started
		// Now iterate through the sockets ArrayList and look for which ones are completed

		StringBuilder tempOutput = new StringBuilder();

		int counter;
		/*
			Method to the madness below:
		
			Each thread is running, and will update its status to reflect whether
			it is still running or not.  Once per second, iterate through all of
			the threads to check and see if they are still running.  If they have completed,
			remove them from the list
		*/
		for (counter = 0; counter < timeout; counter++) {
			if (sockets.size() == 0) {
				break;
			} else {
				for (int i = 0; i < sockets.size(); i++) {
					SocketTest st = (SocketTest)sockets.get(i);
					/*
						It's very important to place nice with the threads and use the lock/unlock
						before accessing their status variables.  Technically this should
						be done with getters and setters, but it's the same idea here.
					*/
					st.lock();
					if (st.isFinished) {
						if (st.hasError) {
							tempOutput.append(st.getDescription() + ":" + st.errorMessage + ",");
							return_code = 2;
						}
						// Now remove this from the list
						sockets.remove(i);
					} 
					st.unlock();
				}
			}
			try {
				// Sleep for 1 second between passes of all of the threads
				Thread.sleep(1000);
			} catch (InterruptedException ie) {
				// do nothing
			}
		}
	
		if (counter == timeout) {
			// One or more threads are still running (in which case the connection has timed out
			// Go back through the list, all of these remaining threads are considered to
			// be timed out
			for (int i = 0; i < sockets.size(); i++) {
				SocketTest st = (SocketTest)sockets.get(i);
				tempOutput.append(st.getDescription() + ":Timed Out,");
			}
			// Doesn't matter what the status code was before, it needs to be 2 now
			return_code = 2;
		}

		// Finally, if return_code is > 0, then take the output from tempOutput and set it accordingly
		if (return_code > 0) {
			// Remove trailing comma
			tempOutput.deleteCharAt(tempOutput.length()-1);
			output = tempOutput.toString();
		} else {	
			// if return_code is still 0, it means none of the sockets timed out
			// and there were no errors on the ones that completed
			output = "All Ports Listening";
		}
	}

	private static void readPortsFromFile() {
		/*
			It's about this time that you start wondering why Java's properties class
			wasn't used here: the reason is simple: Properties files do not allow
			for spaces in the keys unless they are escaped in the file
			
			Since the other monitoring plugins in C/Perl do not have this limitation,
			this home-grown parser is sufficient.  Note that we don't do any validation
			here, just read the lines in the file, split on colons,
			and populate the ports hash.  Validation will be done later
		*/
		int port_count = 0;
		try {
			String line = null;
			BufferedReader in = new BufferedReader(new FileReader(filename));
			while ((line = in.readLine()) != null) {
				if (line.startsWith("#")) {
					continue;
				} else {
					String[] tokens = line.split(":");
					if (tokens.length == 2) {
						ports.put(tokens[0],tokens[1]);
						port_count++;
					}
				}
			}
			if (port_count == 0) {
				System.out.println("No valid ports found in " + displayFilename + ", check syntax");
				System.exit(3);
			}
		} catch (IOException ioe) {
			// File could not be found
			System.out.println(displayFilename + " could not be found");
			System.exit(3);
		}
	}
}

class SocketTest implements Runnable {

	private Socket socket;

	private String description;
	private String IP;
	private int port;

	public boolean isFinished;
	public boolean hasError;
	public String errorMessage;

	private ReentrantLock r;
	
	public SocketTest(String description, String IP, int port) {
		r = new ReentrantLock();
		isFinished = false;
		hasError = false;

		this.description = description;
		this.IP = IP;
		this.port = port;
	}
	
	public void run() {
		// Setup some temporary variables we'll need
		// Attempt to create the socket
		try {
			socket = new Socket(IP,port);
			// If we get here, it worked, close socket
			socket.close();
			// and indicate that no errors were encountered
			setStatus(false,null);
		} catch (IOException ioe) {
			if (ioe.getMessage().compareTo("No route to host") == 0) {
				setStatus(true,"Timed Out");
			} else {
				// Most of the time, this means the connection was refused
				setStatus(true,ioe.getMessage());
			}
		}
	}

	private void setStatus(boolean b,String s) {
		// Note that this method uses the public lock/unlock methods
		// Since the main program thread is relying on lock/unlock to protect
		// its access to hasError and errorMessage, setStatus must as well
		// to prevent deadlocks (otherwise, that defeats the whole purpose
		// of running this in parallel!)
		lock();
		hasError = b;
		errorMessage = s;
		isFinished = true;
		unlock();
	}


	// getDescription: returns the description of what port is being checked by this object
	// does not need to be thread-safe
	public String getDescription() {
		String temp = description + " (" + port + ")";
		return temp;
	}

	// lock and unlock are used both externally and by the object itself
	// to control access to its shared variables

	public synchronized void lock() {
		while (r.isLocked()) {
			try {
				wait();
			} catch (InterruptedException ie) {
			}
		}
		r.lock();
	}

	public synchronized void unlock() {
		r.unlock();
		notifyAll();
	}

}

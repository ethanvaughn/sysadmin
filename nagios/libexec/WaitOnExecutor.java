
/*

	Purpose:	Works in conjunction with an Executor class to provide a timeout on a ServiceCheck.
			Is instantiated with an Executor (which in turn was given a ServiceCheck), and a
			timeout.  Checks the given Executor once per second up to the number of seconds specified
			to see if the Executor has finished running or not.  Used to be part of the Launcher class,
			however it has been abstracted out into its own class to be more generic for different
			databases.  (Oracle, EnterpriseDB, etc.)

	$Id: WaitOnExecutor.java,v 1.1 2008/04/29 12:25:18 jkruse Exp $
	$Date: 2008/04/29 12:25:18 $

*/

public class WaitOnExecutor {

	private static final String version = "$Id: WaitOnExecutor.java,v 1.1 2008/04/29 12:25:18 jkruse Exp $";

	Executor e;
	int timeout;

	public static void main (String[] args) {
		System.out.println(version);
		System.exit(0);
	}
	
	public WaitOnExecutor(Executor e,int timeout) {
		this.e = e;
		this.timeout = timeout;
	}

	public void run() {
		String output = "Database operation timed out";	// Default error message
		int statusCode = 3;				// Default status code
		boolean success = false;
		for (int i = 0; i < timeout; i++) {
			// First wait for the lock to become available
			// this normally shouldn't take that long
			e.lock();
			// Once the lock is obtained, copy e.checkCompleted into a local variable to examine it
			// and then release the lock.  We want to hold onto the lock for as short a time as possible
			success = e.checkCompleted;
			e.unlock();
			// Now, analyze if the check has completed
			if (success) {
				output = e.pluginOutput;
				statusCode = e.statusCode;
				success = true;
				break;
			} else {
				try {
					//System.out.println("Sleeping for 1 second");
					// Sleep for one second and come back and try again
					// If 500ms sleep intervals are desired (for quicker reaponse)
					// multiple the timeout * 2 and change it from 1000 to 500 here,
					// for example.
					Thread.sleep(1000);
				} catch (InterruptedException ie) {
					// Again, ignore.  If only there was something useful to do with this exception
				}
			}
		}
		System.out.println(output);
		System.exit(statusCode);
	}
}

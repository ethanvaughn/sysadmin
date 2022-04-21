import java.util.concurrent.locks.*;

/*
	Purpose:	Provides a wrapper around a ServiceCheck class that facilitates timeouts.
			Basically, all an Executor class does is take a ServiceCheck and executes it,
			and at the same time have a thread-safe boolean to indicate the status
			of the ServiceCheck as to whether it has completed or not.  This class
			works in tandem with the WaitOnExecutor class to provide a timeout on
			ServiceChceks.  This class used to be in the same file as the Launcher class,
			however it is generic across database systems (Oracle, EnterpriseDB, etc.)  To
			better facilitate database abstraction, it is in its own file.
	
	$Id: Executor.java,v 1.1 2008/04/29 12:25:28 jkruse Exp $
	$Date: 2008/04/29 12:25:28 $
*/

public class Executor implements Runnable {

	private static final String version = "$Id: Executor.java,v 1.1 2008/04/29 12:25:28 jkruse Exp $";

	public String pluginOutput;
	public int statusCode;
	public boolean checkCompleted;
	
	private ReentrantLock r;

	ServiceCheck s;

	public static void main(String[] args) {
		System.out.println(version);
		System.exit(0);
	}

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

	public Executor(ServiceCheck s) {
		r = new ReentrantLock();
		this.s = s;
		checkCompleted = false;
	}

	public void run() {
		s.run();
		while (r.isLocked()) {
			try {
				wait();
			} catch (InterruptedException e) {
				// Do nothing!
			}
		}
		r.lock();
		pluginOutput = s.getPluginOutput();	
		statusCode = s.getPluginStatusCode();
		checkCompleted = true;
		r.unlock();
	}
}

import java.sql.*;
//import java.util.*;
import java.text.*;
import java.io.*;

/*
	Purpose:	Returns the number of bytes read/written from
			the database since it was started.  Same basic idea
			as network throughput -- for informational
			purposes only.

	$Id: Database_Throughput.java,v 1.1 2008/04/04 03:27:08 jkruse Exp $
	$Date: 2008/04/04 03:27:08 $
*/

public class Database_Throughput implements ServiceCheck {

	private String pluginOutput;
	private int statusCode;

	private static final String version = "$Id: Database_Throughput.java,v 1.1 2008/04/04 03:27:08 jkruse Exp $";

	private final int interval = 5000;	// in ms, not seconds!
	private final int megabyte = 1048576;

	public static void main (String[] args) {
		System.out.println(version);
		System.exit(0);
	}

	public String getPluginOutput() {
		return pluginOutput;
	}

	public int getPluginStatusCode() {
		return statusCode;
	}

	public void run() {
		DatabaseConnection dbcon = new DatabaseConnection();
		dbcon.connect(
				(String)Launcher.IP,
				(String)Launcher.config.get("sid"),
				(String)Launcher.config.get("port"),
				(String)Launcher.config.get("username"),
				(String)Launcher.config.get("password")
				);
		if (dbcon.isConnected()) {
			// Get the first value
			Throughput t1 = queryAndParseResults(dbcon);

			// Short-circuit: if the first query encountered errors,
			// pluginOutput will be set along with the status code,
			// in which case just return and don't bother with anything else
			if (t1 == null) {
				return;
			}

			// Sleep between queries -- note that the same connection is
			// used for both queries to speed things up
			try {
				Thread.sleep(interval);
			} catch (InterruptedException ie) {
				// Ignore this
			}

			// Get the second value
			Throughput t2 = queryAndParseResults(dbcon);
			
			// Short-circuit: same story as with the first query
			if (t2 == null) {
				return;
			} 
			
			// If both t1 and t2 are defined (meaning we get to here), it's safe to
			// compute the results

			// use a DecimalFormat object to prep the output.  Java's sprintf equivalent
			// (through the Formatter classes) sucks horribly: this is easier
			DecimalFormat outputPrep = new DecimalFormat("#0.00 MB/s");
			int seconds = interval/1000;

			// This looks horrible, but everything has to be cast to a double for these division
			// operations to work.  If the result of each op is not cast to a double, you'll
			// get zero as the result everytime, regardless of the input
			String displayIn = outputPrep.format(((double)(t2.in-t1.in)/(double)megabyte)/(double)seconds);
			String displayOut = outputPrep.format(((double)(t2.out-t1.out)/(double)megabyte)/(double)seconds);

			// For the performance data, just take the results of the second query.  Those are counter-based
			// values, which the grapher will plot accordingly
			pluginOutput = "Read: " + displayIn + " Write: " + displayOut + "|in:" + t2.in + " out:" + t2.out;
			statusCode = 0;

			// Lastly, disconnect the database connection
			dbcon.disconnect();
		} else {
			// We get here if the database could not get connected
			pluginOutput = dbcon.getErrorMessage();
			statusCode = dbcon.getStatusCode();
		}
	}

	// queryAndParseResults: returns a Throughput object in all cases, but this object
	// can be null in case errors occur
	private Throughput queryAndParseResults(DatabaseConnection dbcon) {
		Throughput t = null;
		dbcon.executeQuery(Launcher.SQL);
		if (dbcon.getStatusCode() == 0) {
			ResultSet rs = dbcon.getResults();
			try {
				rs.next(); // Position to the first record (there's only one...)
				long in = rs.getLong("physical_reads");
				long out = rs.getLong("physical_writes");
				t = new Throughput(in,out);
			} catch (SQLException sqe) {
				pluginOutput = "SQL Error: " + sqe.getMessage();
				statusCode = 3;
			}
		} else {
			pluginOutput = dbcon.getErrorMessage();
			statusCode = dbcon.getStatusCode();
		}
		return t;
	}

	// Throughput object: fancy way to allow the queryAndParseResults function to return two values (bytes in/bytes out)
	// to the run() method
	private class Throughput {
		public long in;
		public long out;
		
		public Throughput(long in,long out) {
			this.in = in;
			this.out = out;
		}
	}
}

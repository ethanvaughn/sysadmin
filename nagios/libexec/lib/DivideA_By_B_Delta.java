import java.sql.*;
import java.util.*;
import java.text.*;
import java.io.*;

/*
	Purpose:	Takes deltas of Column A/Column B.  Assumes Columns A and B are incrementing columns
			Very similar in purpose to the connection delta Perl script, except it is taking
			two database columns and storing their values, and using the following forumla:
			
			(column_a - previous_a)/(column_b - previous_b)
			
			Thus for two columns of incrementing values, a delta can be taken of a/b.  Main
			purpose of this class is for values such as CRS block latency.  The queries used
			by Oracle only calculate block latency (where latency is blocks/time used to send)
			since instance startup, which is misleading.  This way, it is always a delta since
			the last time the script ran, instead of instance startup.
	
	$Id: DivideA_By_B_Delta.java,v 1.5 2008/09/16 22:49:15 jkruse Exp $
	$Date: 2008/09/16 22:49:15 $
*/

public class DivideA_By_B_Delta implements ServiceCheck {

	private static final String version = "$Id: DivideA_By_B_Delta.java,v 1.5 2008/09/16 22:49:15 jkruse Exp $";

	private static final String tmpDir = "/u01/app/nagios/tmp"; // tmp directory used for storing deltas

	private String pluginOutput;
	private int statusCode;

	private String column_a;		// Divisor
	private String column_b;		// Dividend
	private String output_format;		// Optional: used by DecimalFormat class to control output display

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

	public DivideA_By_B_Delta() {
		output_format = null;
		statusCode = 0;
	}

	public void run() {
		// Before querying, we need to read the thresholds
		if (readAndValidateThresholds()) {
			queryAndParseResults();
		}
	}

	private void deleteFile(String filename) {
		File f = new File(filename);
		if (f != null) {
			f.delete();
		}
	}

	private void prepareOutput(float a, float b) {
		String tmpFile = tmpDir + "/" + Launcher.hostName + "-" + Launcher.serviceName + ".tmp";
		Properties p = new Properties();
		try {
			p.load(new FileInputStream(tmpFile));
			float previous_a = Float.parseFloat(p.getProperty("a"));
			float previous_b = Float.parseFloat(p.getProperty("b"));
			float value = (a - previous_a)/(b - previous_b);
			if (previous_a > a || previous_b > b) {
				// The previous value is bigger than the current value, which means the DB was most
				// likely restarted.  Nuke previous reading and start over
				pluginOutput = "(Invalid value for delta, resetting)";
				// Need to close out all of our objects here to make sure the file handle goes away
				// Easiest way to do this is to make p go away
				p = null;
				// Save these new a and b values and start over
				writeTempFile(a,b,tmpFile);
			} else if (Float.isNaN(value) || Float.isInfinite(value)) {
				// As a last-ditch effort just take a/b and try that
				value = a/b;
				// Do not write these values to the file -- next run will have a longer interval
				// which will hopefully allow the math to work.  Just output what we have
				if (output_format != null) {
					DecimalFormat outputPrep = new DecimalFormat(output_format);
					pluginOutput = outputPrep.format(value) + "|" + value;
				} else {
					pluginOutput = value + "|" + value;
				}
			} else {
				if (output_format != null) {
					DecimalFormat outputPrep = new DecimalFormat(output_format);
					pluginOutput = outputPrep.format(value) + "|" + value;
				} else {
					pluginOutput = value + "|" + value;
				}
				p = null;
				writeTempFile(a,b,tmpFile);
			}
		} catch (NumberFormatException nfe) {
			// Means the file contained invalid floats, which should not happen!
			pluginOutput = "Unable to read previous value, contact SA Team";
			statusCode = 3;
			// Delete the file and nuke the p object to make sure the filehandle is closed
			p = null;
			deleteFile(tmpFile);
		} catch (IllegalArgumentException iae) {
			// Invalid format was given to the DecimalFormat class
			pluginOutput = "Invalid output format specified";	
			statusCode = 3;
		} catch (IOException ioe) {
			// This just means the file didn't exist, which means this is the first run
			// writeTempFile will set output and statusCode if there were any errors, so rely
			// on its boolean return value before updating output
			if (writeTempFile(a,b,tmpFile)) {
				pluginOutput = "(No Previous Value)";
			}
		}
	}

	private boolean writeTempFile(float a, float b, String file) {
		boolean result = false;
		try {
			FileOutputStream f = new FileOutputStream(file);
			Properties p = new Properties();
			Float float_a = new Float(a);
			Float float_b = new Float(b);
			p.setProperty("a",float_a.toString());
			p.setProperty("b",float_b.toString());
			p.store(f,null);
			result = true;
		} catch (FileNotFoundException fnfe) {
			// This gets thrown when we can't create this file, which should not happen
			pluginOutput = "Unable to write to " + file + ", contact SA Team";
			statusCode = 3;
		} catch (IOException ioe) {
			// Gets thrown when p attempts to store its values in f
			pluginOutput = "Unable to save values: " + ioe.getMessage();
			statusCode = 3;
		}
		return result;
	}

	private void queryAndParseResults() {
		// Establish database connection
		DatabaseConnection dbcon = new DatabaseConnection();
		dbcon.connect(
				(String)Launcher.IP,
				(String)Launcher.config.get("sid"),
				(String)Launcher.config.get("port"),
				(String)Launcher.config.get("username"),
				(String)Launcher.config.get("password")
				);
		// If DB is connected, start the funk
		if (dbcon.isConnected()) {
			dbcon.executeQuery(Launcher.SQL);
			if (dbcon.getStatusCode() == 0) {
				ResultSet rs = dbcon.getResults();
				try {
					rs.next(); // Java is very unhappy if you don't call next even when the RS is just one row
					float count_a = rs.getFloat(column_a);
					float count_b = rs.getFloat(column_b);
					prepareOutput(count_a,count_b);
				} catch (SQLException sqe) {
					pluginOutput = "SQL Error: " + sqe.getMessage();
					statusCode = 3;
				}
				dbcon.disconnect();
			} else {
				pluginOutput = dbcon.getErrorMessage();
				statusCode = dbcon.getStatusCode();
			}
		} else {
			pluginOutput = dbcon.getErrorMessage();
			statusCode = dbcon.getStatusCode();
		}
	}

	private boolean readAndValidateThresholds() {
		String filename = Launcher.customerCode + "/" + Launcher.hostName + "-" + Launcher.serviceName + ".thresholds";
		Properties thresholds = new Properties();	// File will be loaded into this object
		boolean result = false;				// The value to be returned if everything below goes OK
		try {
			thresholds.load(new FileInputStream(Launcher.basedir + "/" + filename));
			// the column name is required.  Everything else is optional
			column_a = thresholds.getProperty("column_a");
			column_b = thresholds.getProperty("column_b");
			if (column_a != null && column_b != null) {
				result = true;
			}
			// output_format is an optional directive which will be used by the DecimalFormat class
			// to control the display of decimal points
			if (thresholds.getProperty("output_format") != null) {
				output_format = thresholds.getProperty("output_format");
			}
		} catch (IOException ioe) {
			// Means the thresholds file could not be found.  While thresholds are optional for
			// this class, column_name is required, therefore the filename is required
			pluginOutput = filename + " could not be found";
			statusCode = 3;
			result = false;
		}
		return result;
	}
}

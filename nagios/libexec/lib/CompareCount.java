import java.sql.*;
import java.util.*;
import java.text.*;
import java.io.*;

/*
	Purpose: Generic class for returning a count.  Thresholds (and output formatting)
	
	$Id: CompareCount.java,v 1.13 2009/07/22 16:45:07 evaughn Exp $
	$Date: 2009/07/22 16:45:07 $
*/

public class CompareCount implements ServiceCheck {

	private static final String version = "$Id: CompareCount.java,v 1.13 2009/07/22 16:45:07 evaughn Exp $";

	private String pluginOutput;
	private int statusCode;

	private int warningCount;
	private int criticalCount;
	private String column_name;		// The column to be retrieved from the query
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

	public CompareCount() {
		// Just to be safe, initialize all of the variables
		// used in comparing the output
		warningCount = 0;
		criticalCount = 0;
		output_format = null;
	}

	public void run() {
		// Before querying, we need to read the thresholds
		if (readAndValidateThresholds()) {
			queryAndParseResults();
		}
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
					float count = rs.getFloat(column_name);
					//System.out.println(Launcher.SQL);

					// At least one threshold (warning or critical) must be defined
					if (warningCount > 0 || criticalCount > 0) {
						/*
							Note that we need to use >, not >= here.  Here's why:
							if >= is used, and it is a service with just a critical
							threshold, it will always come back with a warning.  So the way
							to use this correctly is to adjust the warning/critical
							threshold accordingly.  If it should be critical on 25, use 24 for the
							threshold.  If it should be warning on 10, use 9 for warning
						 */

						if (count > warningCount && warningCount > 0) {
							statusCode = 1;
							// Now test critical
							if (count > criticalCount && criticalCount > 0) {
								statusCode = 2;
							}
						// This case may run if the service has no warning threshold defined
						} else if (count > criticalCount && criticalCount > 0) {
							statusCode = 2;
						} else {
							/*
							   If it's neither critical nor warning, then it must be OK
							   The unknown case is dealt with if there were any errors
							   which would have thrown an exception
							 */
							statusCode = 0;
						}
					// No thresholds were defined 
					} else {
						statusCode = 0;
					}
					String display_output;
					int count_as_int = (int)count;
					if (output_format != null) {
						// An output format was defined (using the DecimalFormat class)
						DecimalFormat outputPrep = new DecimalFormat(output_format);
						display_output = outputPrep.format(count);
					} else {
						/*
							Floating point will be of the format x.xxxx, which is
							not what we want if no output format was specified.
							Thus count_as_int is used to convert the float to an int,
							so it will display as just a number with no decimal points
						*/
						display_output = count_as_int + "";
					}
					pluginOutput = display_output + "|" + count_as_int;
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

		// Test first for the threshold file. If it doesn't exist, set filename to the default.
		try {
			thresholds.load( new FileInputStream( Launcher.basedir + "/" + filename ) );
		} catch (FileNotFoundException fnfe) {
			filename = "default/" + Launcher.serviceName + ".thresholds";
		} catch (IOException ioe) {
			filename = "default/" + Launcher.serviceName + ".thresholds";
		}

		// Now that the correct file has been verified, read it
		try {
			thresholds.load( new FileInputStream( Launcher.basedir + "/" + filename ) );
			// the column name is required.  Everything else is optional
			column_name = thresholds.getProperty( "column_name" );
			if (column_name != null) {
				result = true;
			}
			/*
				column_name is required: both warning and critical are optional
				to avoid triggering the NumberFormatException, only try parsing both
				warning/critical if said keys actually exist
			*/
			if (thresholds.getProperty("warning") != null) {
				warningCount = Integer.parseInt(thresholds.getProperty("warning"));
			}
			if (thresholds.getProperty("critical") != null) {
				criticalCount = Integer.parseInt(thresholds.getProperty("critical"));
			}
			// output_format is an optional directive which will be used by the DecimalFormat class
			// to control the display of decimal points
			if (thresholds.getProperty("output_format") != null) {
				output_format = thresholds.getProperty("output_format");
			}
		} catch (NumberFormatException nfe) {
			/*
				This means we loaded the thresholds file, but it has syntax errors (can't read the numbers
				defined for warning/critical).  While those parameters are optional, if they are present,
				but not valid, error out
			*/
			result = false;
			pluginOutput = "Invalid warning / critical thresholds in " + filename;
			statusCode = 3;
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

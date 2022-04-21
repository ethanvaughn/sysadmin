import java.sql.*;
import java.util.*;
import java.io.*;

/*
	$Id: LDAP_Users.java,v 1.3 2009/07/22 16:45:07 evaughn Exp $
	$Date: 2009/07/22 16:45:07 $
*/

public class LDAP_Users implements ServiceCheck {

	private static final String version = "$Id: LDAP_Users.java,v 1.3 2009/07/22 16:45:07 evaughn Exp $";

	public static void main(String[] args) {
		System.out.println(version);
		System.exit(0);
	}

	private StringBuffer query;
	private String pluginOutput;
	private int statusCode;
	private Properties thresholds;

	private int warningCount;
	private int criticalCount;

	public String getPluginOutput() {
		return pluginOutput;
	}

	public int getPluginStatusCode() {
		return statusCode;
	}

	public void run() {
		// Set statusCode to zero before we get started, since the loop may not
		statusCode = 0;
		thresholds = new Properties();
		// Before querying, we need to read the thresholds and load variables
		if (readAndValidateThresholds() && loadVariables()) {
			queryAndParseResults();
		}
	}

	private void queryAndParseResults() {
		DatabaseConnection dbcon = new DatabaseConnection();
		dbcon.connect(
				(String)Launcher.IP,
				(String)Launcher.config.get("sid"),
				(String)Launcher.config.get("port"),
				(String)Launcher.config.get("username"),
				(String)Launcher.config.get("password")
				);
		if (dbcon.isConnected()) {
			dbcon.executeQuery(Launcher.SQL);
			if (dbcon.getStatusCode() == 0) {
				ResultSet rs = dbcon.getResults();
				StringBuffer tempPluginOutput = new StringBuffer();
				int crossedThreshold = 0; // Need to initialize this here since it is not explicitely initialized elsewhere
				int rowCount = 0;
				try {
					while (rs.next()) {
						int valid_value_count = 0;
						String username = rs.getString("username");
						if (!rs.wasNull()) {
							valid_value_count++;
						}
						int days = rs.getInt("days_since_change");
						if (!rs.wasNull()) {
							valid_value_count++;
						}
						if (days >= warningCount) {
							// If the statusCode was OK on another user, set to warning
							if (statusCode == 0) {
								statusCode = 1;
								crossedThreshold = warningCount;
							}
							// Otherwise if it's critical, regardless of the previous reading, make critical
							if (days >= criticalCount) {
								statusCode = 2;
								crossedThreshold = criticalCount;
							}
							// And finally, append to the output string
							tempPluginOutput.append(username + ":" + days + " days old ");
						}
						if (valid_value_count == 2) {
							rowCount++;
						}
					}
					if (rowCount > 0) {
						if (statusCode == 0) {
							pluginOutput = "All Accounts OK";
						} else {
							pluginOutput = tempPluginOutput.toString() + "(Threshold:" + crossedThreshold + " days)";
						}
					} else {
						pluginOutput = "No Rows Returned from Query";
						statusCode = 3;
					}
					//System.out.println("Status Code: " + statusCode);
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
		boolean result = false;

		// If the specified thresholds file is missing, check for the default ...
		try {
			thresholds.load( new FileInputStream( Launcher.basedir + "/" + filename ) );
		} catch (IOException ioe) {
			filename = "default/" + Launcher.serviceName + ".thresholds";
		}
		
		// Now that the file has been verified, read it ...
		try {
			thresholds.load(new FileInputStream(Launcher.basedir + "/" + filename));
			warningCount = Integer.parseInt(thresholds.getProperty("warning"));
			criticalCount = Integer.parseInt(thresholds.getProperty("critical"));
			result = true;
		} catch (NumberFormatException nfe) {
			result = false;
			pluginOutput = "Missing or invalid warning / critical thresholds in " + filename;
			statusCode = 3;
		} catch (IOException ioe) {
			result = false;
			pluginOutput = filename + " could not be found";
			statusCode = 3;
		}
		return result;
	}

	private boolean loadVariables() {
		String filename = Launcher.customerCode + "/" + Launcher.hostName + "-" + Launcher.serviceName + ".config";
		Properties variables = new Properties();
		boolean result = false;

		// Check first for the specified file, then revert to the default ... 
		try {
			variables.load( new FileInputStream( Launcher.basedir + "/" + filename ) );
		} catch (IOException ioe) {
			filename = "default/" + Launcher.serviceName + ".config";
		}
		
		// Now that the file has been verified, read it
		try {
			variables.load( new FileInputStream( Launcher.basedir + "/" + filename ) );
			String tempSQL = Launcher.SQL;
			Enumeration e = variables.keys();
			while (e.hasMoreElements()) {
				String key = (String)e.nextElement();
				String value = variables.getProperty( key );
				tempSQL = tempSQL.replace( key, value );
			}
			Launcher.SQL = tempSQL;
			result = true;
		} catch (IOException ioe) {
			result = false;
			pluginOutput = filename + " could not be found";
			statusCode = 3;
		}
		return result;
	}
}

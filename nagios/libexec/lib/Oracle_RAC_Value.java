import java.sql.*;
import java.util.*;
import java.text.*;
import java.io.*;

/*
	Purpose:	Returns RAC Values (where hostname must be mapped to instance ID)
			This returns values just like CompareCount, but has to correlate
			values from gv$instance to match instance ID to hostname
	$Id: Oracle_RAC_Value.java,v 1.1 2008/08/14 00:43:08 jkruse Exp $
	$Date: 2008/08/14 00:43:08 $
*/

public class Oracle_RAC_Value implements ServiceCheck {

	private String pluginOutput;
	private int statusCode;

	private static final String version = "$Id: Oracle_RAC_Value.java,v 1.1 2008/08/14 00:43:08 jkruse Exp $";

	// Normally SQL isn't hard-coded, but it makes sense here (for now)
	private final String instanceListSQL = "select host_name,inst_id from gv$instance";

	private HashMap instances;
	private HashMap stats;
	private String column_name;
	private String output_format;
	private int warning;
	private int critical;

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

	// Constructor (used to initialize internal variables)
	public Oracle_RAC_Value() {
		instances = new HashMap();
		stats = new HashMap();
		warning = 0;
		critical = 0;
	}

	public void run() {
		if (readAndValidateThresholds()) {
			DatabaseConnection dbcon = new DatabaseConnection();
			dbcon.connect(
					(String)Launcher.IP,
					(String)Launcher.config.get("sid"),
					(String)Launcher.config.get("port"),
					(String)Launcher.config.get("username"),
					(String)Launcher.config.get("password")
				     );
			if (dbcon.isConnected()) {
				// Get the list of instances
				boolean status = false;
				status = getInstanceList(dbcon);

				// Short-circuit: if the first query encountered errors,
				// pluginOutput will be set along with the status code,
				// in which case just return and don't bother with anything else
				if (status == false) {
					return;
				}

				// Get the stats
				status = getInstanceStats(dbcon);

				// Short-circuit: same story as with the first query
				if (status == false) {
					return;
				} 

				// if we get here, all the queries completed.  We need to correlate the instance to hostname
				if (instances.containsKey(Launcher.hostName)) {
					DecimalFormat outputPrep = new DecimalFormat(output_format);
					Float value = (Float)stats.get(instances.get(Launcher.hostName));
					String displayValue = outputPrep.format(value);
					pluginOutput = displayValue + "|" + value;
					if (value >= warning) {
						if (value >= critical) {
							statusCode = 2;
						} else {
							statusCode = 1;
						}
					} else {
						statusCode = 0;
					}
					statusCode = 0;
				} else {
					pluginOutput = "Unable to match " + Launcher.hostName + " from instance list";
					statusCode = 3;
				}

				dbcon.disconnect();
			} else {
				// We get here if the database could not get connected
				pluginOutput = dbcon.getErrorMessage();
				statusCode = dbcon.getStatusCode();
			}
		} 
	}

	private boolean getInstanceStats(DatabaseConnection dbcon) {
		boolean result = false;
		dbcon.executeQuery(Launcher.SQL);
		if (dbcon.getStatusCode() == 0) {
			ResultSet rs = dbcon.getResults();
			try {
				while(rs.next()) {
					int inst_id = rs.getInt("inst_id");
					float value = rs.getFloat(column_name);
					stats.put(inst_id,value);
				}
				result = true;
			} catch (SQLException sqe) {
				pluginOutput = "SQL Error: " + sqe.getMessage();
				statusCode = 3;
			}
		} else {
			pluginOutput = dbcon.getErrorMessage();
			statusCode = dbcon.getStatusCode();
		}
		return result;
	}

	private boolean getInstanceList(DatabaseConnection dbcon) {
		boolean result = false;
		dbcon.executeQuery(instanceListSQL);
		if (dbcon.getStatusCode() == 0) {
			ResultSet rs = dbcon.getResults();
			try {
				while(rs.next()) {
					String host_name = rs.getString("host_name");
					int end_pos = host_name.indexOf('.');
					host_name = host_name.substring(0,end_pos);
					if (host_name == null) {
						pluginOutput = "Unable to parse instance host name";
						statusCode = 3;
						result = false;
						break;
					} else {
						int inst_id = rs.getInt("inst_id");
						instances.put(host_name,inst_id);
					}
				}
				result = true;
			} catch (SQLException sqe) {
				pluginOutput = "SQL Error: " + sqe.getMessage();
				statusCode = 3;
			}
		} else {
			pluginOutput = dbcon.getErrorMessage();
			statusCode = dbcon.getStatusCode();
		}
		return result;
	}

	private boolean readAndValidateThresholds() {
		String filename = Launcher.customerCode + "/" + Launcher.hostName + "-" + Launcher.serviceName + ".thresholds";
		boolean result = false;
		int arguments_found = 0;
		Properties thresholds = new Properties();
		try {
			thresholds.load(new FileInputStream(Launcher.basedir + "/" + filename));
			// the column name is required.  Since this is a generic class, we will not know
			// what column name will be the output of the SQL query -- so it is a parameter that has to be
			// This determines whether this service -- the boolean will get reset to false
			// if a number format exception is thrown
			column_name = thresholds.getProperty("column_name");
			if (column_name != null) {
				arguments_found++;
			}
			output_format = thresholds.getProperty("output_format");
			if (output_format != null) {
				arguments_found++;
			}
			// Both warning and critical are optional
			if (thresholds.getProperty("warning") != null) {
					warning = Integer.parseInt(thresholds.getProperty("warning"));
			}
			if (thresholds.getProperty("critical") != null) {
				critical = Integer.parseInt(thresholds.getProperty("critical"));
			}
			// If all of the required arguments were found (and no exceptions were thrown)
			// result will get set to true
			if (arguments_found == 2) {
				result = true;
			}
		} catch (NumberFormatException nfe) {
			// If a warning or critical threshold WAS specified, but is not valid
			// (If it simply wasn't found, we don't care)
			result = false;
			pluginOutput = "Invalid warning / critical thresholds in " + filename;
			statusCode = 3;
		} catch (IOException ioe) {
			// Means the thresholds file could not be found
			pluginOutput = filename + " could not be found";
			statusCode = 3;
			result = false;
		}
		return result;
	}
}

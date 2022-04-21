import java.sql.*;
import java.util.*;
import java.io.*;

/*
 * TIE: 	Monitors the database side of TIE
 * Author:	Jake Kruse
 * Version:	1.0
 * History:
 * 		10/03/07: Initial Release
 * Notes
 * 		Assuming that a database connection can be established,
 * 		this service will only enter a warning state, and never critical
 */

public class TIE implements ServiceCheck {

	private String pluginOutput;
	private int statusCode;
	private Properties thresholds;

	private int warningCount;

	public String getPluginOutput() {
		return pluginOutput;
	}

	public int getPluginStatusCode() {
		return statusCode;
	}

	public void run() {
		thresholds = new Properties();
		// Before querying, we need to read the thresholds
		if (readAndValidateThresholds()) {
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
				try {
					rs.next(); // Java is very unhappy if you don't call next even when the RS is just one row
					int count = rs.getInt("count");
					if (count >= warningCount) {
						pluginOutput = "Record Count: " + count + ", Consider Cycling TIE|" + count;
						statusCode = 1;
					} else {
						pluginOutput = "Record Count: " + count + "|" + count;
						statusCode = 0;
					}
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
		try {
			thresholds.load(new FileInputStream(Launcher.basedir + "/" + filename));
			warningCount = Integer.parseInt(thresholds.getProperty("warning"));
			result = true;
		} catch (NumberFormatException nfe) {
			result = false;
			pluginOutput = "Missing or invalid warning / critical thresholds in " + filename;
			statusCode = 3;
		} catch (IOException ioe) {
			result = false;
			pluginOutput = filename + " could not be found";
			//pluginOutput = Launcher.basedir + "/" + filename + " could not be found";
			statusCode = 3;
		}
		return result;
	}
}

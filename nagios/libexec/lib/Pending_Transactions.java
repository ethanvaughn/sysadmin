import java.sql.*;
import java.util.*;
import java.io.*;

public class Pending_Transactions implements ServiceCheck {

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
					int count = rs.getInt("trx_count");
					if (count >= criticalCount) {
						statusCode = 2;
					} else if (count >= warningCount) {
						statusCode = 1;
					} else {
						statusCode = 0;
					}
					pluginOutput = count + " Transactions Pending|" + count;
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
			criticalCount = Integer.parseInt(thresholds.getProperty("critical"));
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

import java.sql.*;
import java.util.*;
import java.io.*;

/*
 * DB_Status: 	Dummy Class to test if instance + listener is working
 * Author:	Jake Kruse
 * Version:	1.0
 * History:
 * 		10/31/07: Initial Release
 */

public class Oracle_DB_Status implements ServiceCheck {

	private String pluginOutput;
	private int statusCode;

	public String getPluginOutput() {
		return pluginOutput;
	}

	public int getPluginStatusCode() {
		return statusCode;
	}

	public void run() {
		queryAndParseResults();
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
					pluginOutput = "Oracle SID " + Launcher.config.get("sid") + " on Port " + Launcher.config.get("port") + " is Up";
					statusCode = 0;
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
}

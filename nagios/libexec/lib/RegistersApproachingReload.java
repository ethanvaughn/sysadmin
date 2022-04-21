import java.sql.*;
import java.util.*;
import java.text.*;
import java.io.*;

/*
	Purpose: General class to execute an SQL and display results.
	Used for testing and as the base for more specific service checks.
	
	$Id: RegistersApproachingReload.java,v 1.1 2009/10/14 18:30:55 evaughn Exp $
	$Date: 2009/10/14 18:30:55 $
*/

public class RegistersApproachingReload implements ServiceCheck {

	private static final String version = "$Id: RegistersApproachingReload.java,v 1.1 2009/10/14 18:30:55 evaughn Exp $";

	private String pluginOutput;
	private int statusCode;


	public static void main (String[] args) {
		System.out.println(version);
		System.exit(0);
	}


	// Methods from ServiceCheck
	public String getPluginOutput() {
		return pluginOutput;
	}


	public int getPluginStatusCode() {
		return statusCode;
	}


	// Constructor
	public RegistersApproachingReload() {
	}


	public void run() {
		queryAndParseResults();
	}


	//----- queryAndParseResults ----------------------------------------------
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
		if (dbcon.isConnected()) {
			dbcon.executeQuery( Launcher.SQL );
			if (dbcon.getStatusCode() == 0) {
				ResultSet rs = dbcon.getResults();
				try {
					rs.next();
					String count = rs.getString( "count" );
					
					// Succcess. Create the output message:
					pluginOutput = "Registers approaching reload: " + count + "|" + count;
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

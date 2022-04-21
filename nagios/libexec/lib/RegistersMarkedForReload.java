import java.sql.*;
import java.util.*;
import java.text.*;
import java.io.*;

/*
	Purpose: General class to execute an SQL and display results.
	Used for testing and as the base for more specific service checks.
	
	$Id: RegistersMarkedForReload.java,v 1.1 2009/10/14 21:57:15 evaughn Exp $
	$Date: 2009/10/14 21:57:15 $
*/

public class RegistersMarkedForReload implements ServiceCheck {

	private static final String version = "$Id: RegistersMarkedForReload.java,v 1.1 2009/10/14 21:57:15 evaughn Exp $";

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
	public RegistersMarkedForReload() {
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
					
					String tot     = rs.getString( "tot" );
					String marked  = rs.getString( "reloads" );
					String percent = rs.getString( "reloads%" );
					
					// Succcess. Create the output message:
					String output = "Registers marked for reload. Total: " + tot + " Marked: " + marked + " Percent: " + percent;
					String metric = "total:" + tot + " marked:" + marked + " percent:" + percent;
					pluginOutput = output + "|" + metric;
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

import java.util.*;
import java.sql.*;

/* 
 	Purpose:	Oracle Database connection class for centralized monitoring
	
	$Id: DatabaseConnection.java,v 1.8 2009/10/14 18:28:13 evaughn Exp $
	$Date: 2009/10/14 18:28:13 $
*/


public class DatabaseConnection {

	private static final String version = "$Id: DatabaseConnection.java,v 1.8 2009/10/14 18:28:13 evaughn Exp $";

	public static void main (String[] args) {
		System.out.println(version);
		System.exit(0);	
	}

	// these two variables are return values to be used when no database connection could be established
	// under normal circumstantes they should not be looked at -- only good if isConnected returns false
	private String errorMessage;
	private int statusCode;

	// SQL Variables
	Statement statement;
	ResultSet resultSet;
	Connection con;

	// some handy control variables
	boolean dbConnectionStatus;

	public DatabaseConnection() {
		// this constructor is really just for initializing all of the variables
		// Java does not like variables that are not initialized

		// init return vars (not always used)
		errorMessage = null;
		statusCode = 3; // assume the worst, set to unknown
		
		// init DB vars
		statement = null;
		resultSet = null;
		con = null;

		// control variables
		dbConnectionStatus = false;
	}

	public String getErrorMessage() {
//System.out.println( "getErrorMessage" );
		return errorMessage;
	}

	public int getStatusCode() {
//System.out.println( "getStatusCode" );
		return statusCode;
	}

	public boolean isConnected() {
//System.out.println( "isConnected" );
		return dbConnectionStatus;
	}

	public ResultSet getResults() {
//System.out.println( "getResults" );
		return resultSet;
	}

	public void connect(String IP,String sid,String port,String username,String password) {
//System.out.println( "connect" );

		// Only timeout on the database connection: the Launcher will take care of timing out the query itself
		// (this needs to be tested!)
		try {
			int connect_timeout = 15; // defaults to 15, but can be overridden by the config file
			if (Launcher.config.containsKey("connect_timeout")) {
				String s = (String)Launcher.config.get("connect_timeout");
				int conf_connect_timeout = Integer.parseInt(s);
			}

			Class.forName("oracle.jdbc.driver.OracleDriver"); // Instantiates oracle's crappy driver
			DriverManager.setLoginTimeout(connect_timeout);

			// This is for DEBUGGING PURPOSES ONLY
			// DO NOT CHECKIN / DEPLOY THIS CLASS UNLESS
			// THE BELOW IS COMMENTED OUT!!!!
			//DriverManager.setLogStream(System.out);

			// There's two types of connections in Oracle, service-based (10g and later) and SID-based (9i and earlier)
			// The big difference is that 10g users a slash and 9i uses a colon.  So how best to handle this?
			// We make a config option in the credentials file, version.  If version is 9i, use the old notation.  Otherwise
			// 10g and later versions use the colon notation.  Note that it appears 9i can do services, it just
			// depends on how it was configured.  Basically what this is saying is that test it both ways if one or the
			// other doesn't work.
			if (Launcher.config.containsKey("style")) {
				String style = (String)Launcher.config.get("style");
				if (style.compareTo("sid") == 0) {
					con = DriverManager.getConnection("jdbc:oracle:thin:@" + IP + ":" + port + ":" + sid,username,password);
				} else {
					dbConnectionStatus = false;
					errorMessage = "Invalid style parameter:" + style;
					statusCode = 3;
				}
			} else {
				// No version is set, use the default connect string (service-based)
				con = DriverManager.getConnection("jdbc:oracle:thin:@" + IP + ":" + port + "/" + sid,username,password);
			}
			// If we get to here we can set dbConnectionStatus to true
			dbConnectionStatus = true;
			// Init statement object
			statement = con.createStatement();
			//statement.setQueryTimeout(query_timeout); // DISABLED: we don't use this anymore
		} catch (NumberFormatException nfe) {
			errorMessage = "Invalid connect_timeout specified in credentials file";
			statusCode = 3;
		} catch (ClassNotFoundException cnfe) {
			errorMessage = "Unable to load Oracle DB Driver, contact SA Team";
			statusCode = 3;
		} catch (SQLException sqe) {
			// Oracle's driver throws one exception for dozens of different errors
			parseConnectError(sqe.getMessage(),IP,port,sid);
		}
	}

	public void disconnect() {
//System.out.println( "disconnect" );
		try {
			con.close();
		} catch (SQLException sqe) {
			//System.out.println("DISCONNECT: " + sqe.getMessage());
			errorMessage = sqe.getMessage();
			statusCode = 3;
		}
	}

	public void executeQuery(String sql) {
//System.out.println( "executeQuery" );
		if (isConnected()) {
			try {
				resultSet = statement.executeQuery(sql);
				// If we get here set statusCode to 0, which means the query has (at least initially)
				// executed OK
				statusCode = 0;
			} catch (SQLException sqe) {
				errorMessage = sqe.getMessage();
				statusCode = 3;
			}
		} else {
			errorMessage = "No database connection";
			statusCode = 3;
		}
	}

	private void parseConnectError(String message,String IP,String port,String sid) {
//System.out.println( "parseConnectError" );
		// IP and port 
		if (message.startsWith("ORA-01017")) {
			// Bad username / password
			errorMessage = "Invalid Username / Password";
			statusCode = 3;
		} else if (message.contains("ORA-12514")) {
			errorMessage = "Invalid service name: " + sid;
			statusCode = 3;
		} else if (message.contains("ORA-12505")) {
			// Bad SID
			// Note this uses contains, not startsWith -- this ORA error
			// is in the middle of the string (Requires JRE 1.5 or later)
			errorMessage = "Invalid SID: " + sid;
			statusCode = 3;
		} else if (message.startsWith("Io exception")) {
			// Can't connect: very bad!
			errorMessage = "Unable to connect to " + IP + ":" + port;
			statusCode = 2;
		} else {
			// Who knows?
			errorMessage = message;
			statusCode = 3;
		}
	}
}

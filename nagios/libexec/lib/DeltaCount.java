import java.sql.*;
import java.util.*;
import java.text.*;
import java.io.*;

/*
	Purpose: Metrics. Gather a running total from the database and report the delta 
    between now and the last check. 
	
	$Id: DeltaCount.java,v 1.2 2008/11/06 22:04:17 evaughn Exp $
	$Date: 2008/11/06 22:04:17 $
*/

public class DeltaCount implements ServiceCheck {

	private static final String version = "$Id: DeltaCount.java,v 1.2 2008/11/06 22:04:17 evaughn Exp $";

	// From the ServiceCheck interface:
	private String pluginOutput;
	private int statusCode;

	private String column_name;   // The column to be retrieved from the query
	private Integer prevCnt; 
	
	private String tmpDir = "/u01/app/nagios/tmp";
	private String tmpFilename = tmpDir + "/" + Launcher.hostName + "-" + Launcher.serviceName;


	public DeltaCount() {
		this.prevCnt = 0;
	}



	public static void main( String[] args ) {
		System.out.println( version );
		System.exit( 0 );
	}



	public String getPluginOutput() {
		return pluginOutput;
	}



	public int getPluginStatusCode() {
		return statusCode;
	}



	/**
		Get the previous numeric value from the temp file. 
		Returns: true if file exists and can be opened.
		         false if file doesn't exist.
	*/
	private boolean readPrevCnt() {
		boolean result = false;
		this.prevCnt = 0;
		FileInputStream fin;		
		try {
			fin = new FileInputStream( this.tmpFilename );
			String strtmp = new BufferedReader( new InputStreamReader( fin ) ).readLine();
			this.prevCnt = Integer.valueOf( strtmp.trim() );
			fin.close();
			result = true;
		} catch (FileNotFoundException e) {
			this.prevCnt = 0;
			this.writeCnt( this.prevCnt );
			result = true;
		} catch (NumberFormatException e) {
			this.prevCnt = 0;
			this.pluginOutput = "NumberFormatException reading " + this.tmpFilename;
			this.statusCode = 3;
			result = false;
		} catch (IOException e) {
			this.pluginOutput = "Exception " + e.getMessage();
			this.statusCode = 3;
			result = false;
		}
		return result;
	}



	/**
		Write the current numeric count to the temp file. 
		Returns: true if file exists and can be opened.
		         false if file doesn't exist.
	*/
	private boolean writeCnt( Integer count ) {
		boolean result = false;
		FileOutputStream fout;
		try {
			fout = new FileOutputStream( this.tmpFilename );
			new PrintStream( fout ).println( count );
			fout.close();
			result = true;
		} catch( IOException e ) {
			this.pluginOutput = "Exception " + e.getMessage();
			this.statusCode = 3;
			result = false;
		}
		return result;
	}




	public void run() {
		// Before querying, we need to read the thresholds
		if (readAndValidateThresholds()) {
			queryAndParseResults();
		}
	}




	private boolean readAndValidateThresholds() {
		String filename = Launcher.customerCode + "/" + Launcher.hostName + "-" + Launcher.serviceName + ".thresholds";
		Properties thresholds = new Properties();	// File will be loaded into this object
		boolean result = false;				// The value to be returned if everything below goes OK
		try {
			thresholds.load( new FileInputStream( Launcher.basedir + "/" + filename ) );
			column_name = thresholds.getProperty( "column_name" );
			if (column_name != null) {
				result = true;
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



	private void queryAndParseResults() {
		// Grab the previous count from the temp file ...
		if (!readPrevCnt()) {
			// Problem reading previous count. Member vars pluginOutput and 
			// statusCode have already been set. Short-circuit.
			return;
		}

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
			dbcon.executeQuery(Launcher.SQL);
			if (dbcon.getStatusCode() == 0) {
				ResultSet rs = dbcon.getResults();
				try {
					rs.next(); // Java is very unhappy if you don't call next even when the RS is just one row
					float count = rs.getFloat( column_name );

					int delta = ((int)count - this.prevCnt);
					if (delta < 0) { delta = 0; }

					if (!this.writeCnt( (int)count )) {
						// Problem writing current count. Member vars pluginOutput and 
						// statusCode have already been set. Short-circuit.
						return;
					}
					
					pluginOutput = delta + "|" + delta;
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

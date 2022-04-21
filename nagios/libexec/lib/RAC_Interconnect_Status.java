import java.sql.*;
import java.util.*;
import java.text.*;
import java.io.*;

/*
	Purpose:	Returns RAC Interconnect Stats for this node

	$Id: RAC_Interconnect_Status.java,v 1.1 2008/08/12 02:40:58 jkruse Exp $
	$Date: 2008/08/12 02:40:58 $
*/

public class RAC_Interconnect_Status implements ServiceCheck {

	private String pluginOutput;
	private int statusCode;

	private static final String version = "$Id: RAC_Interconnect_Status.java,v 1.1 2008/08/12 02:40:58 jkruse Exp $";

	// Normally SQL isn't hard-coded, but it makes sense here (for now)
	private final String instanceListSQL = "select host_name,inst_id from gv$instance";

	private HashMap instances;
	private HashMap stats;

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

	// Constructor (used to initialize hashmaps)
	public RAC_Interconnect_Status() {
		instances = new HashMap();
		stats = new HashMap();
	}

	public void run() {
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
				DecimalFormat outputPrep = new DecimalFormat("#0.00 ms");
				Float latency = (Float)stats.get(instances.get(Launcher.hostName));
				String displayValue = outputPrep.format(latency);
				pluginOutput = "Response Time: " + displayValue + "|" + latency;
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

	private boolean getInstanceStats(DatabaseConnection dbcon) {
		boolean result = false;
		dbcon.executeQuery(Launcher.SQL);
		if (dbcon.getStatusCode() == 0) {
			ResultSet rs = dbcon.getResults();
			try {
				while(rs.next()) {
					int inst_id = rs.getInt("inst_id");
					float latency = rs.getFloat("AVG CR BLOCK RECEIVE TIME (ms)");
					stats.put(inst_id,latency);
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
}

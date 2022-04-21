import java.sql.*;
import java.util.*;
import java.io.*;

public class Tablespace_Usage implements ServiceCheck {

	private String pluginOutput;
	private int statusCode;
	private Properties thresholds;
	private HashMap tablespaces;

	private int default_warning;
	private int default_critical;

	public String getPluginOutput() {
		return pluginOutput;
	}

	public int getPluginStatusCode() {
		return statusCode;
	}

	public void run() {
		thresholds = new Properties();
		tablespaces = new HashMap();

		// Before querying, we need to read the thresholds
		if (readAndValidateThresholds()) {
			queryAndParseResults();
		} else {
			pluginOutput = "Invalid thresholds in thresholds file";
			statusCode = 3;
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
					while (rs.next()) {
						String name = rs.getString("tablespace_name");
						int pct_used = rs.getInt("pct_used");
						if (tablespaces.containsKey(name)) {
							// This tablespace has already been created
							Tablespace t = (Tablespace)tablespaces.get(name);
							t.setPctUsed(pct_used);
							// Now put the updated tablespace back in the hash
							tablespaces.put(name,t);
						} else {
							// This tablespace will get the catch all
							Tablespace t = new Tablespace(name,pct_used,default_warning,default_critical);
							tablespaces.put(name,t);
						}
					}
					dbcon.disconnect();
					// Now all of the tablespaces are accounted for: we need to set pluginOuput and statusCode
					StringBuffer temp_pluginOutput = new StringBuffer();
					Collection c = tablespaces.values();
					Iterator itr = c.iterator();
					while (itr.hasNext()) {
						Tablespace t = (Tablespace)itr.next();
						int thisStatusCode = t.getStatusCode();
						if (thisStatusCode != 0) {
							if (thisStatusCode > statusCode) {
								statusCode = thisStatusCode;
							}
							temp_pluginOutput.append(t.getOutput());
							temp_pluginOutput.append(" ");
						}
					}
					if (statusCode == 0) {
						pluginOutput = "All Tablespaces OK";
					} else {
						pluginOutput = temp_pluginOutput.toString();
					}
				} catch (SQLException sqe) {
					pluginOutput = "SQL Error: " + sqe.getMessage();
					statusCode = 3;
				}
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
		String filename = Launcher.basedir + "/" + Launcher.customerCode + "/" + Launcher.hostName + "-" + Launcher.serviceName + ".thresholds";
		if (! (new File( filename )).exists()) {
			filename = Launcher.basedir + "/default/" + Launcher.serviceName + ".thresholds";
		}
		boolean result = false;
		try {
			// Note that unlike other ServiceCheck classes, this does not use a java properties file:
			// the syntax for this file does not conform to the standard format used in the Properties class,
			// so the parsing is done here with some simple regexs instead.  Note that in order for result to be true
			// we must at a minimum set default_warning and default_critical.  The catch-all is a requirement, while
			// specifying individual tablespaces is optional
			String line = null;
			BufferedReader in = new BufferedReader( new FileReader( filename ) );
			boolean defaultsDefined = false;
			while ((line = in.readLine()) != null) {
				String[] tokens = line.split( " " );
				if (tokens.length == 3) {
					/*
					 * The syntax of this file is as follows:
					 * tablespace <warn %> <crit %>
					 * So for example:
					 * tmx_eul 80 90
					 * And a default catch-all (Required!) as follows (example)
					 * * 80 90
					 */
					if (tokens[0].compareTo("*") == 0) {
						// This is the default
						default_warning = Integer.parseInt(tokens[1]);
						default_critical = Integer.parseInt(tokens[2]);
						defaultsDefined = true;
					} else {
						// Need to create this tablespace object and put it in the tablespaces hash
						Tablespace t = new Tablespace(tokens[0],Integer.parseInt(tokens[1]),Integer.parseInt(tokens[2]));
						tablespaces.put(tokens[0],t);
					}
				}
			}
			// Now check and see if the defaults have been defined (the only requirement)
			if (defaultsDefined) {
				result = true;
			} else {
				pluginOutput = "Missing default threshold in " + filename;
				statusCode = 3;
			}
		} catch (NumberFormatException nfe) {
			// Used for catching errors from the Integer.parseInt method
			result = false;
			pluginOutput = "Missing or invalid warning / critical tablespace thresholds in " + filename;
			statusCode = 3;
		} catch (IOException ioe) {
			result = false;
			pluginOutput = filename + " could not be found";
			statusCode = 3;
		}
		return result;
	}

	private class Tablespace {
		private String name;
		private int pct_used; // The percentage used
		private int warning; // Warning threshold
		private int critical; // Critical threshold

		private String output;
		private int statusCode;

		// This constructor is used for tables who inherit the catch-all tablespace
		// threshold.  In other words, if this tablespace is not specified in the
		// thresholds file, this constructor is used when the query is executed
		// and the default thresholds are used
		public Tablespace(String name, int pct_used, int warning, int critical) {
			this.name = name;
			this.pct_used = pct_used;
			this.warning = warning;
			this.critical = critical;

			// Since we have everything, we can call evaluateStatus now to set the status of this tablespace
			evaluateStatus();
		}

		// This constructor is used when the given tablespace has thresholds specified in the thresholds file.
		// pct_used is omitted here, since it is not know at the time the thresholds file is read (which is before the query runs)
		public Tablespace(String name, int warning, int critical) {
			this.name = name;
			this.warning = warning;
			this.critical = critical;

			// Note that we can't call evaluateStatus yet, since we do not have the pct_used yet in this constructor
		}

		// evaluateStatus: just looks at the threshold, and the pct_used and determines whether this tablespace is OK,Warning, or Critical
		private void evaluateStatus() {
			if (pct_used >= warning) {
				if (pct_used >= critical) {
					statusCode = 2;
				} else {
					statusCode = 1;
				}
				output = name + ":" + pct_used + "%";
			} else {
				output = null;
				statusCode = 0;
			}
		}

		// Used for tablespaces that have thresholds defined -- these tablespace objects are instantiated when the thresholds file is
		// processed, therefore pct_used is not known yet.  When it is known, this method is called to set pct_used, and then call
		// evaluateStatus to set the statusCode and output.
		public void setPctUsed(int pct_used) {
			this.pct_used = pct_used;
			evaluateStatus();
		}

		// these two methods are just the getters used to look at the status and output of this tablespace

		public String getOutput() {
			return output;
		}

		public int getStatusCode() {
			return statusCode;
		}
	}
}

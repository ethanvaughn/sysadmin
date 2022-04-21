import java.io.*;
import java.util.*;
import javax.naming.*;
import javax.rmi.*;
import com.tomax.idm.server.identity.ejb.client.UserIdentityClientHome;
import com.tomax.idm.server.identity.ejb.client.UserIdentityClientRemote;

/*
	$Id: CheckIDM.java,v 1.3 2009/08/18 22:11:57 evaughn Exp $
	$Date: 2009/08/18 22:11:57 $
*/

public class CheckIDM {

	static final String version	= "$Id: CheckIDM.java,v 1.3 2009/08/18 22:11:57 evaughn Exp $";
	static final String usage	= "java CheckIDM -C <Cust> -H <Hostname> -S <Service Description> [-t<optional timeout>]\n    Note: There must be no space after the -t, eg. -t20";
	static final char[] chars	= { 'C', 'H', 'S', 't' };

	static HashMap parsed_args;
	static Integer timeout;

	static String result;
	static int return_code;




	//----- parseTimeout ------------------------------------------------------
	private static void parseTimeout() {
		Integer t = (Integer)parsed_args.get( 't' );
		timeout = t.intValue() * 1000;
	}




	//----- main --------------------------------------------------------------
	public static void main( String[] args ) {
		result = "UNKNOWN: Unknown error.";
		return_code = 3;

		//----- Globals --------------------------------------------
		String basedir = "/u01/home/nagios/monitoring";
		String jnpUrl  = null;

		// Gather command-line arguments
		ArgParse a = new ArgParse( args, chars, version, usage );
		parsed_args = a.args();
		parseTimeout();

		// Build the threshold file path:
		// Strip the ending tag from the service name (eg [SA PAGER])
		String s = (String)parsed_args.get( 'S' );
		String service_name = s.substring( 0, (s.indexOf( '[' ) - 1) );
		s = basedir + '/' + 
			(String)parsed_args.get( 'C' ) + '/' +
			(String)parsed_args.get( 'H' ) + '-' +
			service_name;
		String threshold_file = s.replaceAll( " ", "_" );

		final Properties properties = new Properties();
		try {
			// Load the thresholds as a Properties file:
			properties.load( new FileInputStream( threshold_file ) );

			// Validate required thresholds from the properties file:
			if ( (String)properties.getProperty( "java.naming.factory.initial" ) == null ) {
				System.out.print( "Missing property 'java.naming.factory.initial' from threshold file: " + threshold_file );	
				System.exit( 3 );
			}
			if ( (String)properties.getProperty( "java.naming.factory.url.pkgs" ) == null ) {
				System.out.print( "Missing property 'java.naming.factory.url.pkgs' from threshold file: " + threshold_file );	
				System.exit( 3 );
			}
			if ( (String)properties.getProperty( "java.naming.provider.url" ) == null ) {
				System.out.print( "Missing property 'java.naming.provider.url' from threshold file: " + threshold_file );	
				System.exit( 3 );
			}

			// Set the timeouts.
			properties.put( "jnp.timeout",   timeout.toString() );
			properties.put( "jnp.sotimeout", timeout.toString() );

			// Set the url for display.
			jnpUrl = properties.getProperty( "java.naming.provider.url" );

			// Initialize the JMDI lookup:
			InitialContext ctx = new InitialContext( properties );
			UserIdentityClientHome home = (UserIdentityClientHome) PortableRemoteObject.narrow(
				ctx.lookup( "ejb/TMXUserIdentityClientEJB" ),
				UserIdentityClientHome.class
			);
			UserIdentityClientRemote remote = home.create();
			long userCount = remote.getUserCount();
			//long userCount = 0;
			result = "IDM services available. Users: " + userCount;
			return_code = 0;




		} catch( java.rmi.MarshalException e ) {
			result = "Unable to execute remote procedure: " + e.toString();
			return_code = 2;
			System.out.print( result );	
			System.exit( return_code );


		} catch( FileNotFoundException e ) {
			result = "File not found: " + threshold_file + ": " + e.toString();
			return_code = 3;
			System.out.print( result );	
			System.exit( return_code );


		} catch( IOException e ) {
//			e.printStackTrace();
			result = "IOException " + threshold_file + ": " + e.toString();
			return_code = 3;
			System.out.print( result );	
			System.exit( return_code );


		} catch( javax.naming.NameNotFoundException e ) {
//			e.printStackTrace();
			result = "Error connecting to IDM server [" + jnpUrl + "] Check IP and Port: " + e.toString();
			return_code = 2;
			System.out.print( result );	
			System.exit( return_code );


		} catch( NamingException e ) {
			e.printStackTrace();
			result = "Error connecting to IDM server " + jnpUrl + " [NamingException]: " + e.toString();
			return_code = 2;
			System.out.print( result );	
			System.exit( return_code );


		} catch( javax.ejb.CreateException e ) {
			result = "Error connecting to IDM server " + jnpUrl + " [CreateException]: " + e.toString();
			return_code = 2;
			System.out.print( result );	
			System.exit( return_code );
		}
		
		System.out.print( result );	
		System.exit( return_code );

	}

}

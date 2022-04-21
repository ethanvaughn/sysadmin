package www::cgi::vl;

# vl.pm = View Loaders
# Specific functions to gather the data needed to populate and instantiate views.

use FindBin qw( $Bin );
use lib "$Bin/../..";

use CGI;
use HTML::Template;

use www::cgi::helpers;
use lib::sn;
use lib::ip;
use lib::item;

use strict;

#----- Global ----------------------------------------------------------------
my $cgi = new CGI;
my $tabmenu = www::cgi::helpers::gen_tabmenu( "ADDR" );
my $remote_user = $cgi->remote_user;




#----- get_ip_row -------------------------------------------------------------
# Helper function for view_ipaddrlist to encapsulate the table row for IP addresses.
# Returns a string bounded by "<tr>.*</tr>"
sub get_ip_row {
	my $count       = shift;
	my $rowrec      = shift;
	my $ipclick     = shift;
	my $itemclick    = shift;
	my $delclick    = shift;
	
	my $result = qq|<tr |;
	$result .= qq|class="altrow"| if ($count % 2 == 0);
	$result .= qq|>|;	
#	$result .= qq|<td><a href="$ipclick">$rowrec->{ipaddr}</a></td>|;
#	$result .= qq|<td>$rowrec->{ipaddr}</td>|;
	$result .= qq|<td>$ipclick</td>|;
	$result .= qq|<td>$rowrec->{type_name}</td>|;
	$result .= qq|<td>$rowrec->{comment}</td>|;
	$result .= qq|<td><a href='$itemclick'>$rowrec->{itemname}</a></td>|;
	$result .= qq|<td>$rowrec->{item_comment}</td>|;
	$result .= qq|<td class="nopad">$delclick</td>|;
	$result .= qq|</tr>\n|;

	return $result; 
}
#----- view_ipaddrlist ----------------------------------------------------------
# Parameters: ($dbh, $vars)
# Load the ipaddrlist.tmpl
# Returns an HTML::Template object.
sub view_ipaddrlist {
	my $dbh     = shift;
	my $vars    = shift;

	# Set the navigation defaults.
	my $navback = {
		controller => "main",
		action => "action=list",
		title => "Main"
	};

	my $htmlview;
	my $subtitle;

	my $db_iplist;     # ip addresses in the db
	my $iplist;        # ip addresses in the subnet


	# listview variables:
	# hashref containing display info for an ip row
	my $rowrec = {
		ip_id        => "",
		ipaddr       => "",
		comment      => "",
		type_name    => "",
		item_id      => "",
		itemname     => "",
		item_comment => ""
	};
		
	my $iplistview = ""; # the complete table rows of ipaddresses to send to the view.	
	my $ipclick = "";
	my $itemclick = "";
	my $delclick = "";


	my $type_id;
	my $type_rec;
	my $count;


	my $sn_rec;
	my $cidr;
	if ($vars->{id}) {
		# We have the subnet ID, lookup subnet info.
		$subtitle = "Subnet IP List";

		$sn_rec = lib::sn::getSnById( $dbh, $vars->{id} );
		www::cgi::helpers::chkDB( $dbh );

		my $maskint = lib::ipfunc::ip2int( $sn_rec->{mask} );
		$cidr = lib::ipfunc::int2cidr( $maskint );
		
		# Generate IPs for the full range of the subnet:
		my $netint = lib::ipfunc::ip2int( $sn_rec->{net} );
		$iplist = lib::ipfunc::getIPList( $netint, $cidr );
		
		# Get a list of addresses for this subnet:
		$db_iplist = lib::ip::getIpListBySn( $dbh, $vars->{id} );
		www::cgi::helpers::chkDB( $dbh );

		# Generate the row output for each IP in the subnet. If it exists in
		# the database, display all info, otherwise just the IP itself:
		$count = 1;
		$type_rec->{name} = "";

		foreach my $ip (@$iplist) {			
			# Clear the hash of row data:
			foreach my $key (keys( %$rowrec )) {
				$rowrec->{$key} = "";
			}

			# The first element in @iplist is the network address, the last is broadcast:
			if ($ip == @$iplist[0]) {
				$rowrec->{ipaddr}  = lib::ipfunc::int2ip( $ip );
				$rowrec->{comment} = "-- NETWORK --";
				$iplistview .= get_ip_row( $count, $rowrec, $rowrec->{ipaddr}, "", "" );
				$count++;
				next;
			}
			my @tmp = @$iplist;
			if ($ip == @$iplist[$#tmp]) {
				$rowrec->{ipaddr}  = lib::ipfunc::int2ip( $ip );
				$rowrec->{comment} = "-- BROADCAST --";
				$iplistview .= get_ip_row( $count, $rowrec, $rowrec->{ipaddr}, "", "" );
				$count++;
				next;
			}
						
			# Translate ip address to human readable format:
			$ip = lib::ipfunc::int2ip( $ip );

			# Check to see if this IP is in the list pulled from the db:
			my $found_in_db = 0;
			foreach my $dbrec (@$db_iplist) {
				if ($dbrec->{ipaddr} eq $ip) {
					$found_in_db = 1;

					# Set IP Address fields:
					$rowrec->{ip_id}   = $dbrec->{id};
					$rowrec->{ipaddr}  = $dbrec->{ipaddr};
					$rowrec->{comment} = $dbrec->{comment};

					# Get the currently selected type:
					$type_id = lib::ip::getTypeLink( $dbh, $dbrec->{id} );
					www::cgi::helpers::chkDB( $dbh );
					if ($type_id) {
						$type_rec = lib::ip::getIpTypeById( $dbh, $type_id );
						www::cgi::helpers::chkDB( $dbh );
					}
					$rowrec->{type_name} = $type_rec->{name};
					
					# Set item vars
					$rowrec->{item_id}      = $dbrec->{item_id}      if ($dbrec->{item_id});
					$rowrec->{itemname}     = $dbrec->{itemname}     if ($dbrec->{itemname});
					$rowrec->{item_comment} = $dbrec->{item_comment} if ($dbrec->{item_comment});

					last;
				}
			}
			if ($found_in_db) {
				$ipclick  = '<a href="ipaddr?action=detail&id=' . $rowrec->{ip_id} . '">' . $rowrec->{ipaddr} . '</a>';
				if ($remote_user eq 'admin') {
					$delclick = qq|<a title="Delete IP link to host for $rowrec->{ipaddr}" class="button" href="#" onclick="return del_post( 'ipaddr', 'action=del&id=$rowrec->{ip_id}&subnet_id=$sn_rec->{id}', '$rowrec->{ipaddr}' );">del</a>|;
				} else {
					$delclick = "";
				}
				$itemclick = "../inventory/main?action=detail&id=" . $rowrec->{item_id};
			} else {
				$rowrec->{ipaddr} = $ip;
				if ($remote_user eq 'admin') {
					$ipclick = "<a href=\"ipaddr?action=detailnew&ipaddr=$ip&subnet_id=" . $sn_rec->{id} . '">' . $rowrec->{ipaddr} . '</a>';
				} else {
					$ipclick  = $rowrec->{ipaddr};
				}
				$delclick = "";
			}

			$iplistview .= get_ip_row( $count, $rowrec, $ipclick, $itemclick, $delclick );
			
			$count++;
		}
	} else {
		$subtitle = "Full IP List";

		$db_iplist = lib::ip::getIpList( $dbh );
		www::cgi::helpers::chkDB( $dbh );

		$count = 0;
		foreach my $dbrec (@$db_iplist) {
			# Clear the hash of row data:
			foreach my $key (keys( %$rowrec )) {
				$rowrec->{$key} = "";
			}

			# Set IP address fields:
			$rowrec->{ip_id}   = $dbrec->{id};
			$rowrec->{ipaddr}  = $dbrec->{ipaddr};
			$rowrec->{comment} = $dbrec->{comment};

			# Get the currently selected type:
			$type_id = lib::ip::getTypeLink( $dbh, $dbrec->{id} );
			www::cgi::helpers::chkDB( $dbh );
			if ($type_id) {
				$type_rec = lib::ip::getIpTypeById( $dbh, $type_id );
				www::cgi::helpers::chkDB( $dbh );
			}
			$rowrec->{type_name} = $type_rec->{name};
			
			if ($dbrec->{item_id}) {
				# Set item fields
				$rowrec->{item_id}      = $dbrec->{item_id} if ($dbrec->{item_id});
				$rowrec->{itemname}     = $dbrec->{itemname} if ($dbrec->{itemname});
				$rowrec->{item_comment} = $dbrec->{item_comment} if ($dbrec->{item_comment});
			}

			$ipclick = "<a href=\"ipaddr?action=detail&id=" . $rowrec->{ip_id} . "&listtype=FULL" . '">' . $rowrec->{ipaddr} . '</a>';
			if ($remote_user eq 'admin') {
				$delclick = qq|<a title="Delete IP link to host for $rowrec->{ipaddr}" class="button" href="#" onclick="return del_post( 'ipaddr', 'action=del&id=$rowrec->{ip_id}&listtype=FULL', '$rowrec->{ipaddr}' );">del</a>|;
			} else {
				$delclick = "";
			}
			$itemclick = "../inventory/main?action=detail&id=" . $rowrec->{item_id};

			$iplistview .= get_ip_row( $count, $rowrec, $ipclick, $itemclick, $delclick );
	
			$count++;
		}
	}


	# View
	$htmlview = HTML::Template->new( filename => "../tmpl/ipaddrlist.tmpl", loop_context_vars => 1, die_on_bad_params => 0 );

	$htmlview->param( tabmenu   => $tabmenu );
	$htmlview->param( subtitle  => $subtitle );

	$htmlview->param( user      => $remote_user );
	$htmlview->param( ADMIN     => $remote_user ) if ($remote_user eq "admin");

	$htmlview->param( navback_controller => $navback->{controller} );
	$htmlview->param( navback_action     => $navback->{action} );
	$htmlview->param( navback_title      => $navback->{title} );

	$htmlview->param( subnet_id      => $sn_rec->{id} )      if ($vars->{id});
	$htmlview->param( subnet_net     => $sn_rec->{net} )     if ($vars->{id});
	$htmlview->param( subnet_cidr    => $cidr )              if ($vars->{id});
	$htmlview->param( subnet_mask    => $sn_rec->{mask} )    if ($vars->{id});
	$htmlview->param( subnet_comment => $sn_rec->{comment} ) if ($vars->{id});
	$htmlview->param( subnet_vlan    => $sn_rec->{vlan} )    if ($vars->{id});
	$htmlview->param( iplist         => $iplistview );

	
	return $htmlview;
}




#----- view_ipaddr ----------------------------------------------------------
# Parameters ($dbh, $vars, ["ADD"])
# Load and display the IP Address detail page: ipaddr.tmpl.
# Set state accordingly when the optional parameter $ADD is passed.
sub view_ipaddr {
	my $dbh  = shift;
	my $vars = shift;
	my $ADD  = shift;

	# Set the navigation defaults.
	my $navback = {
		controller => "ipaddr",
		action => "action=list",
		title => "IP List"
	};
	
	
	my $htmlview;
	my $errnav = "ipaddr";
	my $rec;
	my $subnet_id = $vars->{subnet_id} if ($vars->{subnet_id});
	my $type_id;
	my $adminip = "";

	if (!$vars->{listtype}) {
		$vars->{listtype} = "";
	}

	if (!$ADD) {
		# Get the data to populate the edit/update form:
		if (!$cgi->param( 'id' )) {
			www::cgi::helpers::exitonerr( $errnav, "CGI: $errnav: missing param 'id' for ACTION: [$vars->{action}]\n" );
		}
		$rec = lib::ip::getIpById( $dbh, $cgi->param( 'id' ) ); 
		www::cgi::helpers::chkDB( $dbh );
		$subnet_id = $rec->{subnet_id};

		# Get the currently selected type:
		$type_id = lib::ip::getTypeLink( $dbh, $rec->{id} );
		www::cgi::helpers::chkDB( $dbh );
		
		if ($rec->{item_id}) {
			# Check to see if this is the Admin IP:
			my $adminiplist = lib::ip::getAdminIp( $dbh, $rec->{item_id} );
			foreach my $iprec (@$adminiplist) {
				if ($iprec->{id} == $rec->{id}) {
					$adminip = "CHECKED";
					last; 
				}
			}
		}
	}

	if ($vars->{listtype} eq "FULL") {
		$navback->{action} = "action=list";
	} else {
		$navback->{action} = "action=list&id=$subnet_id";
	}

	# IP type dropdown:
	my $type_data = lib::ip::getIpTypeList( $dbh );
	www::cgi::helpers::chkDB( $dbh );
	my @type_id_list;
	my %type_labels;
	foreach my $tmprec (@$type_data) {
		push( @type_id_list, $tmprec->{id} );
		$type_labels{$tmprec->{id}} = $tmprec->{name};
	}

	# Subnet dropdown:
	my $sn_data = lib::sn::getSnList( $dbh );
	www::cgi::helpers::chkDB( $dbh );
	my @subnet_id_list;
	my %sn_labels;
	foreach my $tmprec (@$sn_data) {
		push( @subnet_id_list, $tmprec->{id} );
		$sn_labels{$tmprec->{id}} = "$tmprec->{net}/$tmprec->{mask} | $tmprec->{comment}";
	}

	# Item dropdown:
	my $item_data = lib::item::getItemList( $dbh );
	www::cgi::helpers::chkDB( $dbh );
	my @item_id_list = ( 0 );
	my %item_labels;
	$item_labels{0} = "--- NONE ---";
	foreach my $itemname (sort keys( %$item_data )) {
		push( @item_id_list, $item_data->{$itemname}->{id} );
		$item_labels{$item_data->{$itemname}->{id}} = "$itemname | $item_data->{$itemname}->{comment}";
	}


	# Build the <select> components:
	my $select_type = sprintf( "%s", 
		$cgi->popup_menu(
			-name    => 'type',
			-values  => \@type_id_list,
			-default => $type_id,
			-labels  => \%type_labels
		)
	);
	my $select_sn = sprintf( "%s", 
		$cgi->popup_menu(
			-name    => 'subnet_id',
			-values  => \@subnet_id_list,
			-default => $subnet_id,
			-labels  => \%sn_labels
 		)
	);
	my $select_item = sprintf( "%s", 
		$cgi->popup_menu(
			-name    => 'item_id',
			-values  => \@item_id_list,
			-default => $rec->{item_id},
			-labels  => \%item_labels
		)
	);

	$htmlview = HTML::Template->new( filename => "../tmpl/ipaddr.tmpl", loop_context_vars => 1 );

	$htmlview->param( tabmenu     => $tabmenu );

	$htmlview->param( navback_controller => $navback->{controller} );
	$htmlview->param( navback_action     => $navback->{action} );
	$htmlview->param( navback_title      => $navback->{title} );
	
	$htmlview->param( user      => $remote_user );
	$htmlview->param( ADMIN     => $remote_user ) if ($remote_user eq "admin");

	$htmlview->param( FULL               => $vars->{listtype} ) if ($vars->{listtype} eq "FULL");

	if ($ADD) {
		$htmlview->param( subtitle    => "Add New IP Address" );
		$htmlview->param( ADD         => "ADD" );
		$htmlview->param( ipaddr      => $vars->{ipaddr} )  if ($vars->{ipaddr});
		$htmlview->param( select_sn   => $select_sn );
		$htmlview->param( select_item  => $select_item );
		$htmlview->param( select_type => $select_type );
	} else {
		$htmlview->param( subtitle    => "View/Update IP Address" );
		$htmlview->param( id          => $rec->{id} );
		$htmlview->param( ipaddr      => $rec->{ipaddr} );
		$htmlview->param( comment     => $rec->{comment} );
		$htmlview->param( select_sn   => $select_sn );
		$htmlview->param( select_item  => $select_item );
		$htmlview->param( select_type => $select_type );
		$htmlview->param( adminip    => $adminip );
	}
		
	return $htmlview;
}



#----- view_iptypelist ----------------------------------------------------------
# Parameters: ($dbh, $vars, ADD)
# Returns an HTML::Template object.
sub view_iptypelist {
	my $dbh     = shift;
	my $vars    = shift;
	my $ADD     = shift;
	
	# Set the navigation defaults.
	my $navback; # arrayref: [0]controller, [1]action, [2]title
	$navback->[0] = "main";
	$navback->[1] = "action=list";
	$navback->[2] = "Main";

	my $htmlview;
	my $errnav = "iptype";
	my $iptypelist;
	my $subtitle;
	my $rec;


	if (!$ADD) {
		# Get the data to populate the edit/update form:
		if (!$cgi->param( 'id' )) {
			www::cgi::helpers::exitonerr( $errnav, "CGI: $errnav: missing param 'id' for ACTION: [$vars->{action}]\n" );
		}
		$rec = lib::ip::getIpTypeById( $dbh, $cgi->param( 'id' ) ); 
		www::cgi::helpers::chkDB( $dbh );
	}

	# Paint the picture
	$htmlview = HTML::Template->new( filename => "../tmpl/iptypelist.tmpl", loop_context_vars => 1 );

	$htmlview->param( user      => $remote_user );
	$htmlview->param( ADMIN     => $remote_user ) if ($remote_user eq "admin");

	# Variables for the add/update form
	if ($ADD) {
		$htmlview->param( ADD      => "ADD" );
		$htmlview->param( name     => $vars->{name} ) if ($vars->{name});
	} else {
		$htmlview->param( id       => $rec->{id} );
		$htmlview->param( name     => $rec->{name} );
	}

	# Load the list
	$iptypelist = lib::ip::getIpTypeList( $dbh );
	www::cgi::helpers::chkDB( $dbh );
	# Add the delete field to the iptypelist elements to be used in the loop.
	if ($remote_user eq 'admin') {
		foreach my $rec (@$iptypelist) {
			$rec->{del} = qq|<a title="Delete the ip type $rec->{name}" class="button" href="#" onclick="return del_post( 'iptype', 'action=del&id=$rec->{id}', '| .
			$rec->{name} .
			qq|' );">del</a>|;
		}
	}
	
	$subtitle = "IP Type Maintenance";

	$htmlview->param( tabmenu  => $tabmenu );
	$htmlview->param( subtitle => $subtitle );

	$htmlview->param( navback_controller => $navback->[0] );
	$htmlview->param( navback_action     => $navback->[1] );
	$htmlview->param( navback_title      => $navback->[2] );

	$htmlview->param( listloop => $iptypelist );

	return $htmlview;
}



#----- view_subnet ----------------------------------------------------------
# Parameters (["ADD"])
# Load and display the subnet detail page: subnet.tmpl.
# Set state accordingly when the optional parameter $ADD is passed.
sub view_subnet {
	my $dbh  = shift;
	my $vars = shift;
	my $ADD  = shift;

	# Set the navigation defaults.
	my $navback; # arrayref: [0]controller, [1]action, [2]title
	$navback->[0] = "main";
	$navback->[1] = "action=list";
	$navback->[2] = "Main";

	my $htmlview;
	my $errnav = "subnet";
	my $rec;

	if (!$ADD) {
		# Get the data to populate the edit/update form:
		if (!$cgi->param( 'id' )) {
			www::cgi::helpers::exitonerr( $errnav, "CGI: $errnav: missing param 'id' for ACTION: [$vars->{action}]\n" );
		}

		$navback->[0] = "ipaddr";
		$navback->[1] = "action=list&id=" . $cgi->param( 'id' );
		$navback->[2] = "IP List";

		$rec = lib::sn::getSnById( $dbh, $cgi->param( 'id' ) ); 
		www::cgi::helpers::chkDB( $dbh );
	}


	$htmlview = HTML::Template->new( filename => "../tmpl/subnet.tmpl", loop_context_vars => 1 );

	$htmlview->param( tabmenu     => $tabmenu );

	$htmlview->param( navback_controller => $navback->[0] );
	$htmlview->param( navback_action     => $navback->[1] );
	$htmlview->param( navback_title      => $navback->[2] );

	$htmlview->param( user      => $remote_user );
	$htmlview->param( ADMIN     => $remote_user ) if ($remote_user eq "admin");

	if ($ADD) {
		$htmlview->param( subtitle    => "Add New Subnet" );
		$htmlview->param( ADD         => "ADD" );
		$htmlview->param( net         => $vars->{net} )      if ($vars->{net});
		$htmlview->param( mask        => $vars->{mask} )     if ($vars->{mask});
		$htmlview->param( comment     => $vars->{comment} )  if ($vars->{comment});
	} else {
		$htmlview->param( subtitle    => "View/Update Subnet" );
		$htmlview->param( id          => $rec->{id} );
		$htmlview->param( net         => $rec->{net} );
		$htmlview->param( mask        => $rec->{mask} );
		$htmlview->param( comment     => $rec->{comment} );
	}
		
	return $htmlview;
}



1;

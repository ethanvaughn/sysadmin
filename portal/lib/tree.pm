#!/usr/bin/perl

package lib::tree;

use FindBin qw( $Bin );
use lib "$Bin/..";
use lib::execSQL;

sub buildTree {
	my $href = shift;
	if (ref($href) ne 'HASH') {
		print 'Given: ',ref($href),"\n";
		exit -1;
	}
	# Now we have $id (tree ID), and href (hash ref) that currently contains the name
	# First get all leaves
	my $aref = lib::execSQL::execSQL("select title,left(order_key,18) as order_key from cacti.graph_tree_items where local_graph_id = 0 and graph_tree_id = $href->{id} order by order_key asc");
	my %leaves;
	$href->{children} = []; # We will be adding children to this later
	$href->{hosts} = {};
	foreach my $ref (@$aref) {
		my %leaf;
		my ($id,$parent_id) = get_id_from_key($ref->{order_key});
		$leaf{name} = $ref->{title}; # Set name of this leaf
		$leaf{id} = $id; # Set the ID of this leaf
		$leaf{parent_id} = $parent_id; # Set the parent leaf ID
		$leaf{children} = []; # Will be used on the next pass
		$leaves{$id} = \%leaf; # Add this leaf to the leaves hash
	}
	# Now all the children have parents defined: build the relationships
	while (my ($id,$leaf) = each(%leaves)) {
		# Whether this leaf is at the top of the tree or not, the method
		# for setting its place in its parent's children array is the same.
		# So $parent gets set to either href (the topmost node of the tree)
		# or the leaf with the parent_id referenced from this leaf
		#
		# The whole point of doing this is to preserve the same order as was
		# referenced in the database.  If we just pushed each leaf onto its
		# corresponding parent's children array, we'd lose all ordering
		my $parent;
		if ($leaf->{parent_id} == -1) {
			$parent = $href;
			# A much less intuitive way to do the same
			#@{$href->{children}}[substr($id,length($id)-1,1)-1] = $leaf;
		} else {
			$parent = $leaves{$leaf->{parent_id}};
			# A much less intuitive way to do the same is here (amazingly, this works!)
			#@{$leaves{$leaf->{parent_id}}->{children}}[substr($id,length($id)-1,1)-1] = $leaf;
		}
		# Since all we have done with this if .. else is change what $parent is pointed at,
		# the command to add this leaf to it's parent's children list is the same
		#
		# This child's position in its parent's list of children can be 
		# determined by looking at the last nnn of the child's ID
		# Easiest (and most reliable way) to do this is with this regex
		if ($id =~ /(\d+)$/) {
			@{$parent->{children}}[$1] = $leaf;
		}
		#@{$parent->{children}}[substr($id,length($id)-1,1)-1] = $leaf;
	}
	# All nodes have been filled in.  Now get the graphs
	#
	# This is a nasty query.  Thank the developers of cacti for this hooey
	my $gref = lib::execSQL::execSQL("select cacti.graph_tree_items.local_graph_id,left(order_key,18) as order_key,cacti.graph_templates_graph.title_cache from cacti.graph_tree_items left outer join cacti.graph_templates_graph on cacti.graph_tree_items.local_graph_id = cacti.graph_templates_graph.local_graph_id where cacti.graph_tree_items.local_graph_id > 0 and graph_tree_id = $href->{id} order by order_key asc");
	# Check and make sure a RS was returned
	#die "No graphs found for tree $href->{name}\n" if ref($gref) ne 'ARRAY';
	foreach my $graph_ref (@$gref) {
		next if ref($graph_ref) ne 'HASH';
		my %graph;
		my ($id,$parent_id) = get_id_from_key($graph_ref->{order_key});
		$graph{gid} = $graph_ref->{local_graph_id};
		$graph{name} = $graph_ref->{title_cache};
		$graph{id} = $id;
		$graph{parent_id} = $parent_id;
		# Now everything is set.  Place this graph in its parent's hash
		my $parent = $leaves{$parent_id};
		if ($id =~ /(\d+)$/) {
			@{$parent->{children}}[$1] = \%graph;
		}
		#@{$parent->{children}}[substr($id,length($id)-1,1)-1] = \%graph;
		# For the purposes of display in portal, when a server's details are displayed, we need
		# to be able to lookup that server, and when given a service name, map that to a graph.
		# So in $href there is an anonymous hash named hosts.  Put each hostname into the this hash,
		# and create an anonymous array ref that will be the list of graphs this host has
		if ($graph{name} =~ /^(\w+) - .* - (.*$)/) {
			# This matched the pattern.  Server name is in $1.  (Lowercase it first)
			my $host = lc($1);
			# Service name is in $2
			$graph{service} = $2;
			# Now check and see if we have created graphs for this or not
			if (!(exists($href->{hosts}->{$host}))) {
				# This server has already been processed.  Add graph to array
				$href->{hosts}->{$host} = [];
			}
			# Add graph to array (order is not important)
			push(@{$href->{hosts}->{$host}},\%graph);
		}
	}
	#print "Tree: $href->{name}\n";
	#while (my ($host,$graphs) = each(%{$href->{hosts}})) {
	#	print "Hostname: $host\n";
	#	foreach my $graph(@$graphs) {
	#		print "\t",$graph->{service},' Parent:' ,$graph->{parent_id},"\n";
	#	}
	#}
	# Done!
	return $href;
	#printTree($href,0);
}

sub printTree {
	my ($href,$depth) = @_;
	die 'Not a hash ref' if ref($href) ne 'HASH';
	my $padding;
	for (my $i = 0; $i < $depth; $i++) {
		$padding.= "\t";
	}
	print $padding,$href->{name},"\n";
	$depth++;
	if (exists($href->{children})) {
		foreach my $child (@{$href->{children}}) {
			# This is important.  While every child array is ordered,
			# there may not be anything in certain positions of the array
			# If a graph tree used to have graphs 1,2,3,4,5,6, and we delete 1 and 2,
			# 3,4,5,6 will all remain.  Also, order keys always start at 1, and arrays
			# start at 0, so the first position in every child array (index 0) can be skipped
			# To do this universally, just check if this position in the array is actually
			# a hash ref or not, and only process it if it is.  On this if .. statement we do
			# not return, just skip this child and move onto the next.  (Returning would cause
			# all subsequent children to get ignored)
			if (ref($child) eq 'HASH') {
				printTree($child,$depth);
			} 
		}
	} else {
		return;
	}
}

sub get_id_from_key {
	my $order_key = shift;
	die 'No key passed in to split_key' if !defined($order_key);
	my @id_array;
	# The format for an order key is as follows:
	# nnn.nnn.nnn.nnn..... (starting at 1 for each n)
	# Example: 001001001
	# This specifies leaf 1, subleaf 1 of leaf 1, sub-subleaf 1 of subleaf 1
	# (This could be a graph, or yet another leaf)
	# This iterates over this string, and every 3rd character ($i +1) % 3))
	# Add 1 to $i since string indexes start from zero.  So if ($i+1)%3) == 0,
	# that would be the 3rd character (0 .. 1 .. 2)
	for (my $i = 0; $i < length($order_key); $i++) {
		if (($i+1) % 3 == 0) {
			my $str = substr($order_key,$i-2,3);
			# Once we have the nnn value, remove all LEADING zeros
			# If we removed ALL zeros, if this was the 10th item in a tree, we'd be making it 1
			$str =~ s/^0+//o;
			# It's very important to remove all the leading zeros for the next step.  Right now we are
			# treating these nnn values as strings.  Later, we will treat them as numbers. (after concat'ing)
			# Add that number to @id_array. If we don't have a number, it means 
			# we're at the end of the identifier for this leaf
			# (in the DB, every order_key is zero-padded up to 100 characters)
			if (length($str) > 0) {
				push(@id_array,$str);
			} else {
				# We're done.  No reason to look at the remaining 10 or 20 zeros
				last;
			}
		}
	}
	# Now @id_array has the unique identifier of this leaf.
	# Turn this into a number, and identify this leaf's parent
	my ($id,$parent_id);
	# Parent ID can be obtained by removing the last item off of @id_array
	for (my $i = 0; $i < scalar(@id_array); $i++) {
		# On each pass, append the next value from the array
		# This will be this leaf's unique ID
		if (($i + 1) == scalar(@id_array)) {
			# Last pass: do not add trailing period, and do not append this to parent_id
			$id.= $id_array[$i];
		} else {
			$id.= $id_array[$i].'.';
			$parent_id.= $id_array[$i].'.';
		}
	}
	# Now ID is set, need parent ID
	# If the above loop that iterated over id_array finished on its first pass, than this leaf is
	# at the top of the tree.  Thus we can just check if parent_id is defined. If it is, remove the
	# trailing period that got appended with the above loop.  If not, set to -1, since it is at the top of
	# the tree. (Defining its parent will happen after all leaves have been processed)
	if (defined($parent_id)) {
		chop($parent_id);
	} else {
		$parent_id = -1;
	}
	return $id,$parent_id;
}

1;

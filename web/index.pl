#!/usr/bin/perl

use strict;
use CGI qw(:standard);
use Data::Dumper;
use DBI;

$|++;

open (ERROR, ">>error");
local $SIG{__WARN__} = sub {
    my $msg = shift;
    print ERROR $msg;
};

my $query = new CGI;
my $USERNAME = $ENV{'REMOTE_USER'};
my %defaults = (
	'autopickup'=>'autopickup',
	'checkpoint'=>'checkpoint',
	'confirm'=>'confirm',
	'ignintr'=>'ignintr',
	'legacy'=>'legacy',
	'lit_corridor'=>'lit_corridor',
	'prayconfirm'=>'prayconfirm',
	'safe_pet'=>'safe_pet',
	'sortpack'=>'sortpack',
	'standout'=>'standout',
	'tombstone'=>'tombstone',
	'verbose'=>'verbose',
	'help'=>'help'
	);

my $dbh = DBI->connect("DBI:mysql:host=localhost;database=nethack",
						"nethack",'pM3oh@s.');


&start_html;

$query->import_names('Q');

if ($query->request_method() eq 'POST') {
    if ($query->param('Reset Defaults')) {
		$dbh->do(qq{delete from user_options where username='$USERNAME'});
		print p, "<font color=\"green\">action taken: delete from user_options",
			" where username='$USERNAME'</font>\n";
		print p, '<b>success</b>';
    } 
    else {
		print p,'updating your options in the database...';
		my $ref = $dbh->selectall_arrayref("select name, value from 
			user_options where username='$USERNAME'");
		my %hash;
		if (defined $ref) {
			foreach my $row_ref (@{$ref}) {
				$hash{$row_ref->[0]} = $row_ref->[1];
			}
		}
		my $sth = $dbh->prepare(qq{select name,compound from options order by
				name asc});
		$sth->execute();
		print p;
		print "<table border=0 cellpadding=3 cellspacing=3><tr><td>";
		print "<b>name</b></td><td><b>old value</b></td><td><b>new ";
		print "value</b></td></tr>\n";
		while (my @options = $sth->fetchrow_array()) {
			print '<tr>';
			my $val = &bool_val($query->param("$options[0]"),$options[0],
				$options[1]);
			if ($options[0] eq 'disclose') {
				$val = "+i +a +v +g +c";
			}
			print '<td>'.$options[0].'</td><td>'.  
				$hash{$options[0]}.'</td><td>' .  $val . '</td></tr>';
			if ($val ne $hash{$options[0]})  {
				my $sth2 = $dbh->prepare("select name from user_options
					where username='$USERNAME' and name='$options[0]'");
				$sth2->execute();
				if (my @returns = $sth2->fetchrow_array()) {
				#if it does exist, update (see below)
					$sth2->finish();
					$dbh->do("update user_options set
						value='$val' where username='$USERNAME' and name='$options[0]'");
					if ((! defined $val) || ($val =~ /^$/)) {
						$dbh->do("delete from user_options 
							where username='$USERNAME' and name='$options[0]'");
					}
				}
				else {
				#and if name doesn't exist in user_options, insert
					$sth2->finish();
					$sth2 = $dbh->prepare("insert into user_options values
						(?,?,?,?)");
					$sth2->execute(undef,$USERNAME,$options[0],$val);
					$sth2->finish();
					if ($val =~ /^\s*$/) {
						$dbh->do("delete from user_options where
							where username='$USERNAME' and name='$options[0]'");
					}
				}
			}
		}
		$dbh->do("delete from user_options where username='$USERNAME' and
			name in ('windowtype','traps','scores', 'pickup_burden',
			'objects','name','monsters','effects','dungeon')");
		print "</table>\n";
		print p,'hit the back button in your browser to modify your options again.';
		$sth->finish();
	}
}
else {
    print $query->start_multipart_form('POST');
    print p, "<a href=\"http://www.antisymmetric.com/cgi-bin/password.pl?".
             "user=$USERNAME\">Change My Password</a>";
    print p, "<b>Set what options?</b>";
    print p, "Booleans (selecting will toggle value), Compounds (give more than true/false)";
    print p, "<table border=0 cellpadding=3 cellspacing=3>\n";
    print p, "<tr><td><b>name</b></td><td><b>definition</b></td><td><b>value</b></td></tr>\n";
	
	my $sth = $dbh->prepare (qq{select name,definition,compound from options 
		order by name asc});
	$sth->execute();
	while (my @options = $sth->fetchrow_array()) {
		print "<tr>";
		print "<td>$options[0]</td><td>$options[1]</td><td>";
		&printCell($options[0], $options[2]);
		print "</td></tr>\n";
	}
	$sth->finish();
	print "</table>\n";
    
    print p, $query->submit(-name=>'Update My Nethack Options'),
           ("&nbsp" x 5), $query->submit(-name=>'Reset Defaults');
    
    print $query->endform;
}


sub printCell {
	my $option_name = shift;
	my $username = $USERNAME;
	my $compound = shift;
	my $sth = $dbh->prepare(qq{select value from user_options where
		username='$USERNAME' and name='$option_name'});
	$sth->execute();
	if (my $href = $sth->fetchrow_hashref()) {
		#print Dumper($href),"compound:$compound";
		#if user already has this option in the database
		if (!$compound) { #and it is a boolean options
			#print checkbox
			my $default = ($href->{'value'} eq 'false') ? undef : $option_name;
			print $query->checkbox_group(-name=>"$option_name",
				-values=>["$option_name"],
				-defaults=> [ $default ]);
		}
		else { #compound type
			if ($option_name eq 'name') {
				print "$USERNAME";
			}
			if ($option_name eq 'disclose') {
				print "all";
			}
			if ($option_name eq 'catname') {
				if (defined $href->{'value'}) {
             		print $query->textfield(-name=>'catname', -size=>15,
                   			     -default=>$href->{'value'});
				} else {
             		print $query->textfield(-name=>'catname', -size=>15,
                        		-default=>"null");
				}
            }
            if ($option_name eq 'dogname') {
				if (defined $href->{'value'}) {
                	print $query->textfield(-name=>'dogname', -size=>15,
                    	-default=>$href->{'value'});
				}
				else  {
                	print $query->textfield(-name=>'dogname', -size=>15,
                    	-default=>'null');
				}
            }
            if ($option_name eq 'horsename') {
				if (defined $href->{'value'}) {
                	print $query->textfield(-name=>'horsename', -size=>15,
						-default=>$href->{'value'});
				}
				else {
                	print $query->textfield(-name=>'horsename', -size=>15,
						-default=>'null');
				}
            }
            if ($option_name eq 'msghistory') {
				if (defined $href->{'value'}) {
                	print $query->textfield(-name=>'msghistory', -size=>6,
						-default=>$href->{'value'});
				}
				else {
                	print $query->textfield(-name=>'msghistory', -size=>6,
						-default=>'');
				}
            }
            if ($option_name eq 'pettype') {
				if (defined $href->{'value'}) {
                	print $query->popup_menu(-name=>'pettype', -values=>['random','dog','cat'], -defaults=>[$href->{'value'}]);
				}
				else {
                	print $query->popup_menu(-name=>'pettype', -values=>['random','dog','cat'], -defaults=>['random']);
				}
            }
            if ($option_name eq 'align') {
				if (defined $href->{'value'}) {
                	print $query->popup_menu(-name=>'align', -values=>['', 'lawful','neutral','chaotic'],
                      -defaults=>[$href->{'value'}]);
				}
				else {
                	print $query->popup_menu(-name=>'align', -values=>['', 'lawful','neutral','chaotic'],
                      -defaults=>['']);
				}
            }
           if ($option_name eq 'gender') {
			   if (defined $href->{'value'}) {
                print $query->popup_menu(-name=>'gender', -values=>['', 'female', 'male'],
                     -defaults=>[$href->{'gender'}]);
			   }
			   else {
                print $query->popup_menu(-name=>'gender', -values=>['', 'female', 'male'],
                     -defaults=>['']);
				}
            }
            if ($option_name eq 'fruit') {
			   if (defined $href->{'value'}) {
                print $query->textfield(-name=>'fruit', -size=>'20', 
					-default=>$href->{'value'});
			   }
			   else {
                print $query->textfield(-name=>'fruit', -size=>'20', 
					-default=>$href->{'slime mold'});
			   }
            }
            if ($option_name eq 'windowtype') {
                print "tty";
            }
            if ($option_name eq 'menustyle') {
				if (defined $href->{'value'}) {
                print $query->popup_menu(-name=>'menustyle', 
						-values=>['full', 'partial','traditional',
                   	   'combination'],
                    	  -defaults=>[$href->{'value'}]);
				}
				else {
                print $query->popup_menu(-name=>'menustyle', -values=>['full', 'partial','traditional',
                      'combination'],
                      -defaults=>['full']);
				}
            }
            if ($option_name eq 'packorder') {
				if (defined $href->{'value'}) {
                	print $query->textfield(-name=>'packorder', -size=>'15', 
					default=>$href->{'value'});
				}
				else {
                	print $query->textfield(-name=>'packorder', -size=>'15', default=>'$")[%?+!=/(*`0_');
				}
            }
            if ($option_name eq 'pickup_burden') {
                print "stressed";
            }
            if ($option_name eq 'pickup_types') {
				if (defined $href->{'value'}) {
                	print $query->textfield(-name=>'pickup_types', -size=>'15', default=>$href->{'value'});
				}
				else {
           	     	print $query->textfield(-name=>'pickup_types', -size=>'15', default=>'all');
				}
            }
            if ($option_name eq 'scores') {
                print "3 top/2 around<br>";
                print "or <a href=\"http://antisymmetric.com/slashem/scores.html\">score list</a>";
            }
            if ($option_name eq 'player_selection') {
                print "dialog";
            }
            if ($option_name eq 'boulder') {
                print '`';
            }
			if ($option_name eq 'race') {
				if (defined $href->{'value'}) {
					print $query->popup_menu(-name=>'race',
					-values=>['','elf','gnome',
					'hobbit','human','orc'],
					-defaults=>[$href->{'value'}]);
				}
				else {
					print $query->popup_menu(-name=>'race',
					-values=>['','elf','gnome',
					'hobbit','human','orc'],
					-defaults=>['']);
				}
			}
			if ($option_name eq 'role') {
				if (defined $href->{'value'}) {
					print $query->popup_menu(-name=>'role',
					-values=>['','Archeologist','Barbarian','Caveman',
					'Healer','Knight','Monk',
					'Priest','Rogue','Ranger','Samurai',
					'Tourist','Valkyrie','Wizard'], 
					-defaults=>[$href->{'value'}]);
				}
				else {
					print $query->popup_menu(-name=>'role',
					-values=>['','Archeologist','Barbarian','Caveman',
					'Healer','Knight','Monk',
					'Priest','Rogue','Ranger','Samurai',
					'Tourist','Valkyrie','Wizard'],
					-defaults=>['']);
				}
			}
			if ($option_name eq 'suppress_alert') {
				if (defined $href->{'value'}) {
				print $query->popup_menu(-name=>'suppress_alert',
					-values=>['3.4.0', '3.3.1'], -defaults=>[$href->{'value'}]);
				}
				else {
				print $query->popup_menu(-name=>'suppress_alert',
					-values=>['3.4.0', '3.3.1'], -defaults=>['']);
				}
			}
		}
	}
	else {
		if (!$compound) {
			#print checkbox
			my $default = $defaults{$option_name};
			print $query->checkbox_group(-name=>"$option_name",
				-values=>["$option_name"],
				-defaults=> [ $default ]);
		}
		else {
			print $href->{'value'};
			if ($option_name eq 'name') {
				print "$USERNAME";
			}
			if ($option_name eq 'disclose') {
				print "all";
			}
			if ($option_name eq 'catname') {
             print $query->textfield(-name=>'catname', -size=>15,
                        -default=>'My Kitty');
            }
            if ($option_name eq 'dogname') {
                print $query->textfield(-name=>'dogname', -size=>15,
                    -default=>'My Woofy');
            }
            if ($option_name eq 'horsename') {
                print $query->textfield(-name=>'horsename', -size=>15,
					-default=>'Woah');
            }
            if ($option_name eq 'msghistory') {
                print $query->textfield(-name=>'msghistory', -size=>6);
            }
            if ($option_name eq 'pettype') {
                print $query->popup_menu(-name=>'pettype', -values=>['random','dog','cat']);
            }
			if ($option_name eq 'race') {
				print $query->popup_menu(-name=>'race',
					-values=>['','elf','gnome', 'hobbit','human',
					'orc'],
					-defaults=>['']);
			}
			if ($option_name eq 'role') {
				print $query->popup_menu(-name=>'role', 
				-values=>['','Archeologist','Barbarian','Caveman',
					'Healer','Knight','Monk',
					'Priest','Rogue','Ranger','Samurai',
					'Tourist','Valkyrie','Wizard'], -defaults=>['']);
			}
            if ($option_name eq 'align') {
                print $query->popup_menu(-name=>'align', -values=>['', 'lawful','neutral','chaotic'],
                      -defaults=>['']);
            }
           if ($option_name eq 'gender') {
                print $query->popup_menu(-name=>'gender', -values=>['', 'female', 'male'],
                     -defaults=>['']);
            }
            if ($option_name eq 'fruit') {
                print $query->textfield(-name=>'fruit', -size=>'20', -default=>'slime mold');
            }
            if ($option_name eq 'windowtype') {
                print "tty";
            }
            if ($option_name eq 'menustyle') {
                print $query->popup_menu(-name=>'menustyle', -values=>['full', 'partial','traditional',
                      'combination'],
                      -defaults=>['full']);
            }
            if ($option_name eq 'packorder') {
                print $query->textfield(-name=>'packorder', -size=>'15', default=>'$")[%?+!=/(*`0_');
            }
            if ($option_name eq 'pickup_burden') {
                print "stressed";
            }
            if ($option_name eq 'pickup_types') {
                print $query->textfield(-name=>'pickup_types', -size=>'15', default=>'all');
            }
            if ($option_name eq 'scores') {
                print "3 top/2 around<br>";
                print "or <a href=\"http://antisymmetric.com/slashem/scoreboard\">score list</a>";
            }
            if ($option_name eq 'player_selection') {
                print "dialog";
            }
            if ($option_name eq 'boulder') {
                print '`';
            }
			if ($option_name eq 'suppress_alert') {
				print $query->popup_menu(-name=>'suppress_alert',
					-values=>['','3.4.0','3.3.1','3.2'], -defaults=>['']);
			}
		}
	}

	$sth->finish();
}

sub bool_val {
	#new value, #name, #compound?
	my ($a, $b, $compound) = @_; 

	if (!$compound) {
		if (!defined $b) {
			return "true";
		}
		return ($a eq $b) ? "true" : "false";
	}
	else {

		return ($a eq $b) ? "$b": "$a";
	}
}

sub start_html {
    print $query->header;
    print "<html><head><title>Modify ---Nethackrc---</title>",
      "<style type=\"text/css\">\n",
      "<!--\n",
      "  BODY { font-family:helvetica } \n",
      "  P { font-family:helvetica } \n",
      "  TD { font-family:helvetica; font-size:small } \n",
      "A:link { color: #0000ff;text-decoration:none } \n",
      "A:visited { color:#6600bb;text-decoration:none } \n",
      "A:hover { color: #6600bb;text-decoration:underline } \n",
      "A:active { color:#0000ee;text-decoration:underline } \n",
      "//-->\n</style>\n</head>\n<body bgcolor=\"\#ffffff\">\n";
    print "<h2>Antisymmetric Nethackrc Editor</h2>\n";
}

sub end_html {
    print p, "<hr noshade>";
    print "<font size=\"small\">Pooya Woodcock, pooya (at) math.umd.edu",
          "</font>";
    print "</body></html>";
	$dbh->disconnect();
}

&end_html;


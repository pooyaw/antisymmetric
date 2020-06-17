#!/usr/bin/perl

############################################################################
#
# Copyright (C) 2002 Pooya Woodcock <pooya@math.umd.edu>
#
# 	This program is free software; you can redistribute it and/or modify
#	it under the terms of the GNU General Public License as published by
#	the Free Software Foundation; either version 2 of the License, or
#	(at your option) any later version.
#
#	This program is distributed in the hope that it will be useful,
#	but WITHOUT ANY WARRANTY; without even the implied warranty of
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#	GNU General Public License for more details.
#
#	You should have received a copy of the GNU General Public License
#	along with this program; if not, write to the Free Software Foundation,
#	Inc., 59 Temple Place - Suite 330, Boston, MA 02111, USA.
#
###########################################################################

use strict;

use Data::Dumper;
use DBI;

$|++;

# set up the database handle to mysql
my $dbh = DBI->connect ("DBI:mysql:host=localhost;database=nethack",
						"nethack",$PASSWORD);

sub handler {
    my ($sig) = @_;
#    print "\n\ncaught a sig $sig, but I am not shutting down.\n";
#    print " either complete the login or close your terminal and",
#          " try again.\n\n";
}

# enable some security - disable ctrl-c, ctrl-z, and others.
$SIG{'INT'} = 'handler';
$SIG{'QUIT'} = 'handler';
$SIG{'ABRT'} = 'handler';
$SIG{'STOP'} = 'handler';
$SIG{'TSTP'} = 'handler';
$SIG{'QUIT'} = 'handler';
$SIG{'TRAP'} = 'handler';
$SIG{'HUP'}  = 'handler';

# set up globals
my ($username, $password, $stat);
my $URL_LOCATION     = "http://antisymmetric.com/nethack/";
my $URL_OPT_LOCATION = "http://antisymmetric.com/nethack/options/";
my $HACKDIR          = "/usr/games/lib/nethackdir";
my $NETHACK          = "/usr/games/nethack";
my $SAVEDIR          = "$HACKDIR/save";
my $RECOVER          = "$HACKDIR/recover";
my $LOGFILE          = "$HACKDIR/logfile";
my $ADMIN_EMAIL      = 'root@antisymmetric.com';
my $NETHACK_STAT     = "/usr/games/nethack-stat.pl";
my $HTDBM            = "/usr/local/apache/bin/htdbm";
my $USERS_DBM        = "/usr/local/apache/htdocs/nethack/options/usersdbm";
my $COMPRESS         = "gzip";
my $PLAYBACKDIR      = "/usr/games/playback";
my $SAVE_FILE_ULEN   = 5;
my $TTYREC           = "$PLAYBACKDIR/ttyrec";
my $TTYPLAY          = "$PLAYBACKDIR/ttyplay";
my $TTYPLAY_ARGS     = "-p"; 
my $RECLIST          = "/usr/games/reclist";
my $RECLIST_ARGS     = "-fs -ns 1";
my $UID              = `grep '^nethack' /etc/passwd | cut -d: -f3`; chomp $UID; 

# determine the number of concurrent nethack users
my $num_hackers = `w | grep '^nethack' | wc -l`;
chomp $num_hackers;
$num_hackers =~ m/[^\d]*(\d+)[^\d]*/;
$num_hackers = $1;
my $more_num = `w | grep '^slashem' | wc -l`;
chomp $more_num;
$more_num =~ m/[^\d]*(\d+)[^\d]*/;
$more_num = $1;
$num_hackers = $num_hackers + $more_num;
# make backspace not put the yucky ^H^H^H^H^H

print <<'EOF';

 -D. Au          \||/               
                 |  @___oo      n e t h a c k    s e r v e r     
       /\  /\   / (__,,,,|                v. 3.4.3
      ) /^\) ^\/ _)             
      )   /^\/   _)         
      )   _ /  / _)         w/ Jukka's Monolithic Bug-Fix/Goodie Patch
  /\  )/\/ ||  | )_)          
EOF

print <<"EOF";
 <  >      |(,,) )__)       $URL_LOCATION
EOF

print <<'EOF';
  ||      /    \)___)\      
  | \____(      )___) )___
   \______(_______;;; __;;;  

EOF


#stty erase
system("stty erase ");

# clean up database connections and 
# try to minimize the perl memory and mysql leaks
sub end_script {
	my ($lvl,$sleep) = @_;
	$dbh->disconnect;
	sleep($sleep) if $sleep;
	exit(0);
}

# print initial welcome statement and hacker count.
# for example: there are currently <a> out of <b> hackers on this server,
# where <a> is current num of hackers and <b> is select count(user) from
# users table.
my $uptime = `uptime`;
print "\n $uptime";
my $initial_sth = $dbh->prepare(qq{select count(1) as total from users});
$initial_sth->execute();
my $total = $initial_sth->fetchrow_hashref();
print "\n There are currently $num_hackers out of " . 
	$total->{'total'} . " registered gamers on this server.\n\n";
$initial_sth->finish();

my $i = 0;
unless ($username) {
    die "authentication failed.\n" if ++$i >= 4;
    print "username: ";
    $username = <STDIN>;
    chomp $username;
    if ($username =~ /^ *$/) { 
		print "invalid username.\n"; 
		&end_script(0,0);
	}
    $username =~ s/\s//g;
}

if (-e "$HACKDIR/perm_lock") {
	system("rm -f $HACKDIR/perm_lock");
	print '*** please e-mail '.$ADMIN_EMAIL.' to remove ***'."\n";
	print "*** the perm_lock.\n";
	&end_script(0,8);
}

my $href = &userOk;
if ($href->{'newuser'} eq "true") {
    print "Are you sure you want to add $username ([no]/yes)? ";
    my $response = <STDIN>;
    if ($response !~ /^y/i) {
       print "\n User add aborted. Quitting.";
       &end_script(0,2);
    }
	my $testusername = substr($username,0,5);
    print "creating new user $username (testing $testusername)...\n";
	my $sth = $dbh->prepare(qq{select username from users where username like '$testusername%'});
	$sth->execute();
	if (my $row = $sth->fetchrow_hashref()) {
		my $testusername2 = substr($row->{'username'},0,5);
		if ($testusername2 eq $testusername) {
		print "user already exists (note that the FIRST FOUR CHARACTERS \n";
		print "must be unique; sorry, that's how nethack names files.).\n";
		print "log in and choose another. press <enter> to logout.\n";
		my $get_enter = <STDIN>;
		$sth->finish();
		&end_script(0,0);
		}
	}
	$sth->finish();
    print "done.\n";
    while (! defined $password)  {
            system("/bin/stty -echo");
            print "choose your password: ";
            $password = <STDIN>;
			print "\nagain: ";
			my $further_password = <STDIN>;
			if ($password ne $further_password) {
				print "passwords don't match!\n\n";
				$password = undef;
			}
			else {
            	print "\n\n";
            	chomp $password;
			}
			system("/bin/stty echo");
    }
	$sth = $dbh->prepare(qq{insert into users values (?,?)});
	$sth->execute($username,$password);
	$sth->finish();
    print "change your settings at $URL_OPT_LOCATION\n";
    print "just for now, I'll set a minimal config:\n";
    print "do you like using the number_pad over the vi keys ([no]/yes)? ";
    my $ans = <STDIN>;
    chomp $ans;
	$ans = ($ans =~ /n|^$/i) ? "false" : "true";
	$sth = $dbh->prepare(qq{insert into user_options values (?,?,?,?)});
	$sth->execute(undef,$username,'number_pad',$ans);
	$sth->finish();

    print "\n + adding you to apache's password file...\n";
	system("$HTDBM -b $USERS_DBM \"$username\" \"$password\"");
    print "+++log back in again for settings to take effect...+++\n";
    sleep 5;
}
else {
    my $playAgain = 1;
    print "(existing user) ";
    unless ($password) {
        system("/bin/stty -echo");
        print "password: ";
        $password = <STDIN>;
        print "\n\n";
        system("/bin/stty echo");
        chomp $password;
    }

	if ("$password" ne "$href->{'password'}") {
        print "authentication failure.\n";
        print "connection closing....";
        print "\n";
		&end_script(0,0);
    }
		
    my $TERM = `echo \$TERM`;
    print "\n + Your terminal type is currently: $TERM\n";

    while ($playAgain !~ /^(l|q)|^$/) {
        print "\n";
        print "  +-----------------------------------------+ \n";
        print "  |  p  Display All Nethack Scores.         | \n";
    	print "  |  d  Display Standard Nethack Scores.    | \n";
        print "  |  s  Display Overall Nethack Statistics. | \n";
		print "  |  L     - List Player Stats.             | \n";
		print "  |  D     - List Deadly Levels.            | \n";
		print "  |  x     - List of Most Popular Deaths.   | \n";
        print "  |                                         | \n";
        print "  |  w  Watch Someone's Nethack Game!       | \n";
        print "  |                                         | \n";
        print "  |  m  Display My Nethack Scores.          | \n";
		print "  |                                         | \n";
        print "  |  R  Play Nethack (allow recording)      | \n";
		print "  |  r  |----> without recording.           | \n";
		print "  |                                         | \n";
        print "  |  h  Help                                | \n";
		print "  |  Z  change my password                  | \n";
        print "  |                                         | \n";
        print "  |  l  Logout                              | \n";
        print "  +-----------------------------------------+ \n\n";
        print "Your choice: ";
    	$playAgain = <STDIN>;
        if ($playAgain =~ /^p/i) { 
			system("$HACKDIR/nethack -s all | less");
		}
        if ($playAgain =~ /^w/i) {
              &watch;
        }
        if ($playAgain =~ /^d/) {
			system("$HACKDIR/nethack -s 10 | less");
        }
        elsif ($playAgain =~ /^s/) {
			system("$NETHACK_STAT  | less");
        }
        elsif ($playAgain =~ /^L/) {
             system("$NETHACK_STAT -l S | less");
        }
        elsif ($playAgain =~ /^D/) {
             system("$NETHACK_STAT -d | less");
        }
        elsif ($playAgain =~ /^x/) {
             system("$NETHACK_STAT --expand-reasons -D | less");
        }
        elsif ($playAgain =~ /^m/i) {
			system("nethack -s $username | less");
        }
        elsif ($playAgain =~ /^Z/i) {
              print "new password: ";
              system("/bin/stty -echo");
              my $firstPW = <STDIN>;
              print "\nonce again, please: ";
              my $secondPW = <STDIN>;
              system("/bin/stty echo");
              if ($firstPW ne $secondPW) {
                   print "\n\n xxx passwords don't match. sorry. xxx \n";
				   print "press <enter> to continue...";
				   my $ent = <STDIN>;
              }
              else {
				  chomp $secondPW;
              	print "\n\n +++ password successfully changed. +++ \n";
			  	my $sth = $dbh->prepare(qq{update users set password='$secondPW'
			  		where username='$username'});
			  	$sth->execute();
			  	$sth->finish();
				system("$HTDBM -x $USERS_DBM $username");
				system("$HTDBM -b $USERS_DBM '$username' '$secondPW'");
				print "\nmysql nethack.users table modified. looks good.\n";
				print "press <enter> to continue...";
				my $ent = <STDIN>;
              }
         }
        elsif ($playAgain =~ /^h/i) {
             print "\n   head over to $URL_LOCATION \n";
             print "   if you want to change your nethack options quickly \n";
             print "   and easily (not just ascii chars w/ no color....)  \n";
             print "   or if you want to have an alternate way of checking \n";
             print "   your scores. \n\n";
			 print "Press <enter> to continue...";
			 my $PRESS_ENTER=<STDIN>;
        }
        elsif ($playAgain =~ /^R/) {
			&check_recover($username);
          system("rm -rf /usr/local/apache/htdocs/nethack/rcfiles/$username.opt");
          my $info = $href->{'opt'};
          $info =~ s/\\//g;
		  system ("touch /usr/local/apache/htdocs/nethack/rcfiles/$username.opt");
          system("echo \'".$info."\' >/usr/local/apache/htdocs/nethack/rcfiles/$username.opt");
          system("cd $PLAYBACKDIR ; $TTYREC $username");
        }
		elsif ($playAgain =~ /^r/) {
			&check_recover($username);
			print "\n";
			print "+++ not recording +++ starting nethack...\n";
			sleep 1;
        	system("export NETHACKOPTIONS='".
				 $href->{'opt'}."'; $NETHACK -u $username");
		}
    }
}

sub check_recover {
	my $user = shift;
	my $chopped_username = $user;
	if (length($chopped_username) > $SAVE_FILE_ULEN) {
		$chopped_username = substr ($user, 0, $SAVE_FILE_ULEN);
	}
	if (-e "$HACKDIR/$UID$chopped_username.0") {
		print "I found another nethack running under $user \n\n";
		print "press <enter> to continue.\n";
		my $enter = <STDIN>;

		print "checking for a running nethack (nethack -u $user)...\n";
		my $running_nethack = `ps wax | grep 'n[e]thack -u $user'`;
		if ($running_nethack =~ /\w/) {
			print "FOUND:\n",
				  "   + $running_nethack\n",
				  "killing your runaway nethack instance...\n",
				  "press <enter> to continue.\n";
			$enter = <STDIN>;
			$running_nethack =~ m/^[ ]*([0-9]+)/;
			my $nethack_pid = $1;
			system ("kill $nethack_pid");
			print "killed nethack with process id $nethack_pid.\n",
				  "checking for running nethack (again).\n",
				  "press <enter> to continue.\n";
			$enter = <STDIN>;
			my $nethack_again = `ps wax | grep 'n[e]thack -u $user'`;
			if ($nethack_again !~ /\w/) {
				print "no more nethacks to kill, excellent :) \n";
			}
			else {
				print "big boo boo, email $ADMIN_EMAIL.\n";
				print "press <enter> to continue.\n";
				$enter = <STDIN>;
				&end_script(0,0);
			}
		}

		print "recovering your previous game...\n";
		print "press <enter> to continue.\n";
		$enter = <STDIN>;
		if (-e "$HACKDIR/$UID$chopped_username.0") {
			print "executing: ./recover $UID$chopped_username...\n";
			system("$RECOVER $UID$chopped_username");
			print "compressing save file...\n";
			system("$COMPRESS $SAVEDIR/$UID$chopped_username");
			print "done!\n\n";
		}
		else {
			print "done!\n\n";
		}
		print "press <enter> to continue.";
		my $enter = <STDIN>;
	}
}

sub watch {
    print "\n\n";

print <<'FOO';

    +---------------------------------------------------------+

       these games available to be watched in real-time, 
       right now. You won't see the full screen of the
       other user until he/she changes the level or ^R.
        *** TO STOP PLAYBACK, TYPE <ctrl>-c ***

FOO
    my @w = `ps axw`;
    my %movieHash;
    my %done;
    my $i = 1;
    foreach my $w (@w) {
       chomp;
       if ($w =~ /playback\/ttyrec (.*)/) {
           my $dude = $1;
           $dude =~ s/ +//g;
           $movieHash{"$i"} = $dude;
		   my $idle = "?";
		   my $other_w = `w | grep 'playback/ttyrec'`;
		   if ($other_w =~ /playback\/ttyrec $dude/) {
			   $other_w =~ m/ +([\d:]+) \/usr.*playback\/ttyrec $dude/;
			   $idle = $1;
		   }
           print "           $i      $dude" . "'s game (idle: $idle mins)\n" 
                if ((! defined $done{$dude}) || ($done{$dude} != 1));
          if ($i % 7 == 0) { print "Press <enter> to continue..."; my $foo = <>; }
          $i++ if ((! defined $done{$dude}) || ($done{$dude} != 1));
           $done{$dude} = 1;
       }
    }

    print "\n";
    if ($i == 1) { print "           <none>   \n"; }
    my $realMax = $i;
print <<'foo2';
      
      - - - - - - - - - - - - - O R - - - - - - - - - - - - -

       these are full playback archives of users. you may 
       watch every nethack game a user played on this box 
       using this feature. You may REMOVE your movie file by 
       typing 'r', and following the instructions.

foo2

    my @ls = `ls -oh $PLAYBACKDIR | grep -v 'total' | grep -v 'ttyplay' | grep -v 'ttyrec' | grep -v 'ttytime'`;
    foreach (@ls) {
        s/[rw-]+ +\d+ +nethack//;
        m/\s+([\-_a-zA-Z0-9]*)$/;
        $movieHash{"$i"} = $1;
        chomp $movieHash{"$i"};
        print "           $i$_";
        $i++;
        my $foo;
        if (($i == 7) || (($i % 14 == 0) && ($i > 14)))  { print "\nPress <enter> to continue, <q> to quit."; 
          $foo = <>; 
          system("clear; echo ; echo \"    +---------------------------------------------------------+\" ");
        }
        if ($foo =~ /q/i) { goto OUTER; }
    }
    print "\n";
 

OUTER: print <<'foo3';

           r      Reset my movie file to null. 
           c      Copy my movie file to another name, for
                  later viewing.
        <other>   Back to main menu.

    +---------------------------------------------------------+

foo3

    print "Your choice (r,c,movie number): ";
    my $movieAns = <STDIN>; 
    chomp $movieAns;
 
    if ($movieAns =~ /^\d+$/) {
        if ($movieAns < $i) {
          print "\n    are you sure you want to play back ".$movieHash{$movieAns}. "'s moves ([no]/yes)? "; 
          my $yn = <STDIN>;
         if ($yn =~ /^y/i) {
               if ($movieAns < $realMax && ($realMax != 1)) {
				   system("clear ; $TTYPLAY $TTYPLAY_ARGS $PLAYBACKDIR/".$movieHash{$movieAns});
               }
               else {
				   print "\n   enter a speed to playback [1(normal),2,3,4,5]: ";
				   my $speed = <STDIN>;
				   chomp $speed;
				   if ($speed =~ /^(1|2|3|4|5)$/) {
					   print "\n+++ playing back at speed $speed +++\n";
					   sleep 1;
                   		system("clear ; $TTYPLAY -s $speed $PLAYBACKDIR/".$movieHash{$movieAns});
				   }
				   else {
					   print "\n+++ playing back at speed 1 (normal) +++\n";
					   sleep 1;
                   		system("clear ; $TTYPLAY $PLAYBACKDIR/".$movieHash{$movieAns});
				   }
                }
         }
         else {
           print "ok.\n";
         }
       }
       else {
          print " bad option. movie doesn't exist. invoking Data::Dumper\n";
          print Dumper(\%movieHash);
       }
    }
    if ($movieAns =~ /^r$/i) {
       print "Are you sure you want to reset ".
              "$PLAYBACKDIR/$username (yes/[no])? ";
       my $rem = <STDIN>;
       if ($rem =~ /^y|Y/i) {
          system(">$PLAYBACKDIR/$username");
       }
       else { print "ok.\n"; }
    }
	if ($movieAns =~ /^c$/i) {
		print "Type the name of the new file: ";
		my $file_name = <STDIN>;
		chomp $file_name;
		$file_name =~ s/\.//g;
		$file_name =~ s/ +//g;
		$file_name =~ s/\t//g;
		$file_name =~ s/\///g;
		$file_name =~ s/\*|\?//g; 
		print "Are you sure you want to copy \n".
		"$PLAYBACKDIR/$username to $PLAYBACKDIR/$file_name (yes/[no])? ";
		my $rem = <STDIN>;
		if ($rem =~ /^y|Y/i) {
			if (-e "$PLAYBACKDIR/$file_name") {
				print "file already exists. For security reasons, please \n";
				print "e-mail root\@antisymmetric.com if you want this file\n";
				print "removed.\n";
				print "press  <enter> to continue...";
				my $enter = <STDIN>;
			}
			else {
			system("cp $PLAYBACKDIR/$username \"$PLAYBACKDIR/$file_name\"");
			print "done.";
			print "press <enter> to continue...";
			my $enter = <STDIN>;
			}
		}
		else {
			print "ok. I'm not copying.\n\n";
			print "press <enter> to continue...";
			my $enter = <STDIN>;
		}
	}
}

sub parse {
	my $options;
	my $sth = $dbh->prepare (qq{select * from user_options where 
								username='$username'});
	$sth->execute();
	while (my $row = $sth->fetchrow_hashref()) {
		if ($row->{'value'} eq 'false') {
			$options .= '!' . $row->{'name'} . ',';
		}
		elsif ($row->{'value'} eq 'true') {
			$options .= $row->{'name'} . ',';
		}
		else {
			$options .= $row->{'name'} . '=' . $row->{'value'} . ',';
		}
	}
	$options =~ s/,$//;
	return "$options";
}
	


sub userOk {
    return undef if (! defined $username);
	my $sth = $dbh->prepare (qq{select * from users where username='$username'});
	$sth->execute();
	if (my $row = $sth->fetchrow_hashref()) {
		my $opt = &parse;
		return {
			password => $row->{'password'},
			newuser => 'false',
			opt => "$opt"
		};
	}
	$sth->finish();
	return { 
		password => '',
		opt => '',
		newuser => 'true'
	};
}

print <<'EOF';
                       .      
             /^\     .        
        /\   "V"              Score list 
EOF

print <<"EOF";
       /__\\   I      O  o          + $URL_LOCATION
EOF

print <<'EOF';
      //..\\  I     .         
      \].`[/  I               Options
EOF

print <<"EOF";
      /l\\/j\\  (]    .  O           + $URL_OPT_LOCATION
EOF
print <<'EOF';
     /. ~~ ,\/I          .      
     \\L__j^\/I       o
      \/--v}  I     o   .                   Happy hacking  ^-^
      |    |  I   _________
      |    |  I c(`       ')o
      |    l  I   \.     ,/      -Row
    _/j  L l\_!  _//^---^/\/\_
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
EOF


#!/usr/bin/env perl

use strict;
use warnings;

use lib '/home/rawley/perl5/lib/perl5',
  '/home/rawley/Projects/slapbird/agent/cgi/lib';

use DBI;
use SlapbirdAPM::Agent::CGI;
use CGI;

my $dbh = DBI->connect('dbi:SQLite:dbname=file.db', '', '');

my $sth = $dbh->prepare(q[select time('now');]);
$sth->execute();
my $time     = $sth->fetch->[0];
my $response = 'Hello World! It is ' . $time . " o'clock";

my $cgi = CGI->new();

print $cgi->header();
print <<'END'
<!DOCTYPE html>
<html>
  <body>
    <p>$response</p>
  </body>
</html>
END

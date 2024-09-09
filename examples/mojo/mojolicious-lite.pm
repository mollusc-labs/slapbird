#!/usr/bin/env perl

use strict;
use warnings;

use Mojolicious::Lite -signatures;
use DBI;

my $dbh = DBI->connect('dbi:SQLite:dbname=file.db','','');

plugin 'SlapbirdAPM', key => '<YOUR API KEY>';

get '/' => sub {
  my ($c) = @_;
  my $sth = $dbh->prepare(q[SELECT time('now');]);
  $sth->execute();
  my $time = $sth->fetch->[0];
  return $c->render(text => 'Hello World! It is ' . $time . q[ o'clock]);
};

app->start;

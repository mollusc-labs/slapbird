#!/usr/bin/env perl

use strict;
use warnings;

use Dancer2;
use Plack::Builder;
use DBI;

my $dbh = DBI->connect('dbi:SQLite:dbname=file.db', '', '');

$dbh->do('create table if not exists names (name VARCHAR, age INT)');

get '/' => sub {
  my $sth = $dbh->prepare(q[select time('now');]);
  $sth->execute();
  my $time = $sth->fetch->[0];
  'Hello World! It is ' . $time . q[ o'clock];
};

builder {
  enable 'SlapbirdAPM', key => '<YOUR API KEY>';
  app;
};

use strict;
use warnings;
use Dancer2;
use DBI;

BEGIN {
# would usually be in config.yml
  set plugins => {SlapbirdAPM => {key => '<YOUR API KEY>'}};
}

use Dancer2::Plugin::SlapbirdAPM;

my $dbh = DBI->connect('dbi:SQLite:dbname=file.db', '', '');

$dbh->do('create table if not exists names (name VARCHAR, age INT)');

set port => 3030;

get '/' => sub {
  my $sth = $dbh->prepare(q[select time('now');]);
  $sth->execute();
  my $time = $sth->fetch->[0];

  'Hello World! It is ' . $time . " o'clock";
};

get '/name/:name' => sub {
  my $name = route_parameters->get('name');
  my $sth  = $dbh->prepare('insert into names (name, age) values (?, ?)');
  $sth->execute($name, 23);
  $sth = $dbh->prepare(q[select name from names where name like ?]);
  $sth->execute($name);
  my $name_from_db = $sth->fetch->[0];
  return 'Inserted your name! ' . $name_from_db;
};

dance;

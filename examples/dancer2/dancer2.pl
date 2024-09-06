use strict;
use warnings;
use Dancer2;
use DBI;

BEGIN {
# would usually be in config.yml
  set plugins => {SlapbirdAPM => {key => '01J73YVM6MZX5AG93FCEZWD57Emy-app'}};
}

use Dancer2::Plugin::SlapbirdAPM;

my $dbh = DBI->connect('dbi:SQLite:dbname=file.db','','');

set port => 3030;

get '/' => sub {
  my $sth = $dbh->prepare(q[SELECT time('now');]);
  $sth->execute();
  my $time = $sth->fetch->[0];
  'Hello World! It is ' . $time . " o'clock";
};

get '/foo' => sub {
  'flarb';
};

dance;

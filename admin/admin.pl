use strict;
use warnings;

use Plack::Builder;
use Plack::Response;
use DBI;
use Dotenv -load;

my $dbh = DBI->connect($ENV{ADMIN_DB_DSN}, $ENV{ADMIN_DB_USERNAME},
  $ENV{ADMIN_DB_PASSWORD}, {});

my $app = sub {
  my ($env) = @_;
  my $request = Plack::Request->new($env);

  if ($request->path ne '/') {
    return Plack::Response->new(404)->finalize;
  }
  my $response = Plack::Response->new(200);
  $response->content_type('text/html');
  my $users = $dbh->selectall_arrayref('select * from users', {Slice => {}});
  $response->body(map { $_->{name} } @$users);
  return $response->finalize();
};

builder {
  enable 'SlapbirdAPM';
  $app;
};

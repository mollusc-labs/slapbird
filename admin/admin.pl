use strict;
use warnings;

use Plack::Builder;
use Plack::Response;
use HTML::Tiny;
use DBI;
use Dotenv -load;

my $dbh = DBI->connect($ENV{ADMIN_DB_DSN}, $ENV{ADMIN_DB_USERNAME},
  $ENV{ADMIN_DB_PASSWORD}, {});

my $html = HTML::Tiny->new;

my $app = sub {
  my ($env) = @_;
  my $request = Plack::Request->new($env);

  if ($request->path ne '/') {
    return Plack::Response->new(404)->finalize;
  }
  my $response = Plack::Response->new(200);
  $response->content_type('text/html');
  my $summaries = $dbh->selectall_arrayref(
    'select name, count(ht.http_transaction_id) as total from applications a left join http_transactions ht on a.application_id = ht.application_id group by name',
    {Slice => {}}
  );

  $response->body($html->html([
    $html->head($html->title('SlapbirdAPM statistics page')),
    $html->body([
      $html->h1('Slapbird insights'),
      $html->div([
        map { $html->p([$_->{name}, ' - ', $_->{total}]) } @$summaries
      ])
    ])
  ]));

  return $response->finalize();
};

my $authen = sub {
  my ($username, $password) = @_;
  return $username eq $ENV{ADMIN_USERNAME} && $password eq $ENV{ADMIN_PASSWORD};
};

builder {
  enable 'SlapbirdAPM';
  enable 'Auth::Basic', authenticator => $authen;
  $app;
};

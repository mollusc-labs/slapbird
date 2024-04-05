package Plack::Middleware::SlapbirdAPM;

use strict;
use warnings;

use parent qw( Plack::Middleware );
use Time::HiRes;
use Try::Tiny;
use Plack::Request;
use Const::Fast;
use AnyEvent::HTTP;
use JSON::MaybeXS;
use Devel::Peek qw(mstats_fillhash);
use namespace::clean;

use Plack::Util::Accessor qw(key);

const my $SLAPBIRD_APM_URI => 'slapbirdapm.com/apm';

sub _call_home {
  my ($dto, $key) = @_;

  return http_post(
    headers           => {'x-slapbird-apm' => $key, 'content-type' => 'application/json'},
    body              => encode_json($dto->as_hashref),
    $SLAPBIRD_APM_URI => sub { }
  );
}

sub call {
  my ($self, $env) = @_;

  my $request = Plack::Request->new($env);
  return [200, ['Content-Type' => 'text/plain'], 'OK']
    if $request->uri->path eq 'slapbird/health_check' || $request->uri->path eq '/slapbird/health_check';

  my $start_time = time;
  my $error;
  my $response;

  my %mstats_before;
  try {
    mstats_fillhash(%mstats_before);
  }

  try {
    $response = $self->app->($env);
  }
  catch {
    $error = $_;
  };

  my %mstats_after;
  try {
    mstats_fillhash(%mstats_after);
  }
  my $end_time = time;

  _call_home(
    {
      type          => 'plack',
      method        => $request->method,
      end_point     => $request->uri->path,
      start_time    => $start_time,
      end_time      => $end_time,
      response_code => $response->[0],
      response_size => undef,
      request_size  => $request->content_length,
      requestor     => $request->headers->header('x-slapbird-name'),
      error         => $error,
      %mstats_after && %mstats_before ? (mstats => {before => \%mstats_before, after => \%mstats_after}) : ()
    },
    $self->key
  );

  return $response;
}

1;

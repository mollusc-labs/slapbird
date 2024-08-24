package Plack::Middleware::SlapbirdAPM;

use strict;
use warnings;

use parent qw( Plack::Middleware );
use Time::HiRes;
use Try::Tiny;
use Plack::Request;
use Plack::Response;
use Const::Fast;
use JSON::MaybeXS;
use LWP::UserAgent;
use Carp ();
use System::Info;
use Time::HiRes qw(time);
use namespace::clean;

$Carp::Internal{__PACKAGE__} = 1;

use Plack::Util::Accessor qw(key quiet);

const my $SLAPBIRD_APM_URI => $ENV{SLAPBIRD_APM_DEV}
  ? $ENV{SLAPBIRD_APM_URI} . '/apm'
  : 'https://slapbirdapm.com/apm';

sub _unfold_headers {
    my ( $self, $headers ) = @_;
    my %headers = (@$headers);
    return \%headers;
}

sub _call_home {
    my ( $self, $request, $response, $env, $start_time, $end_time, $error ) =
      @_;

    my $pid = fork();

    return if $pid;

    my %response;

    $response{type}          = 'plack';
    $response{method}        = $request->method;
    $response{end_point}     = $request->uri->path;
    $response{start_time}    = $start_time;
    $response{end_time}      = $end_time;
    $response{response_code} = $response->status;
    $response{response_headers} =
      $self->_unfold_headers( $response->headers->psgi_flatten_without_sort() );
    $response{response_size} = $response->content_length;
    $response{request_id}    = undef;
    $response{request_size}  = $request->content_length;
    $response{request_headers} =
      $self->_unfold_headers( $request->headers->psgi_flatten_without_sort() );
    $response{error}     = $error;
    $response{os}        = System::Info->new->os;
    $response{requestor} = $request->header('x-slapbird-name');
    $response{handler}   = undef
      ; # TODO: (rf) Find a way to find something meaningful to fill this slot with.

    my $ua = LWP::UserAgent->new();
    my $slapbird_response;

    try {
        $slapbird_response = $ua->post(
            $SLAPBIRD_APM_URI,
            'Content-Type'   => 'application/json',
            'x-slapbird-apm' => $self->key,
            Content          => encode_json( \%response )
        );
    }
    catch {
        Carp::carp(
'Unable to communicate with Slapbird, this request has not been tracked got error: '
              . $_ );
        exit 0;
    };

    if ( !$slapbird_response->is_success ) {
        if ( $slapbird_response->code eq 429 ) {
            Carp::carp(
"You've hit your maximum number of requests for today. Please visit slapbirdapm.com to upgrade your plan."
            ) unless $self->quiet;
        }
        Carp::carp(
'Unable to communicate with Slapbird, this request has not been tracked got status code '
              . $slapbird_response->code );
    }

    exit 0;
}

sub call {
    my ( $self, $env ) = @_;

    $self->{key} //= $ENV{SLAPBIRDAPM_API_KEY};

    if ( !$self->key ) {
        Carp::carp(
'SlapbirdAPM key not set, cannot communicate with SlapbirdAPM. Pass key => "MY KEY", or set the SLAPBIRDAPM_API_KEY environment variable.'
        );
        return $self->app->($env);
    }

    my $request = Plack::Request->new($env);
    return [ 200, [ 'Content-Type' => 'text/plain' ], 'OK' ]
      if $request->uri->path eq '/slapbird/health_check/'
      || $request->uri->path eq '/slapbird/health_check';

    my $start_time = time * 1_000;
    my $error;
    my $response;
    my $plack_response;

    try {
        $plack_response = $self->app->($env);
        $response       = Plack::Response->new(@$plack_response);
    }
    catch {
        $error = $_;
    };

    my $end_time = time * 1_000;

    $self->_call_home( $request, $response, $env, $start_time,
        $end_time, $error );

    if ($error) {
        Carp::croak($error);
    }

    return $response->finalize;
}

1;

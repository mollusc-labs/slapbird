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
use SlapbirdAPM::Plack::DBIx::Tracer;
use POSIX ();
use namespace::clean;

$Carp::Internal{__PACKAGE__} = 1;

use Plack::Util::Accessor qw(key quiet ignored_headers);

const my $SLAPBIRD_APM_URI => $ENV{SLAPBIRD_APM_DEV}
  ? $ENV{SLAPBIRD_APM_URI} . '/apm'
  : 'https://slapbirdapm.com/apm';
const my $OS => System::Info->new->os;

sub _unfold_headers {
    my ( $self, $headers ) = @_;
    my %headers = (@$headers);
    if ( $self->ignored_headers && ref( $self->ignored_headers ) eq 'ARRAY' ) {
        delete $headers{$_} for ( @{ $self->ignored_headers } );
    }
    return \%headers;
}

sub _call_home {
    my ( $self, $request, $response, $env, $start_time, $end_time, $queries,
        $error )
      = @_;

    my $pid = fork();

    return if $pid;

    try {

        my %response;

        $response{type}          = 'plack';
        $response{method}        = $request->method;
        $response{end_point}     = $request->uri->path;
        $response{start_time}    = $start_time;
        $response{end_time}      = $end_time;
        $response{response_code} = $response->status;
        $response{response_headers} =
          $self->_unfold_headers(
            $response->headers->psgi_flatten_without_sort() );
        $response{response_size} = $response->content_length;
        $response{request_id}    = undef;
        $response{request_size}  = $request->content_length;
        $response{request_headers} =
          $self->_unfold_headers(
            $request->headers->psgi_flatten_without_sort() );
        $response{error}       = $error;
        $response{os}          = $OS;
        $response{requestor}   = $request->header('x-slapbird-name');
        $response{num_queries} = scalar @$queries;
        $response{queries}     = $queries;
        $response{handler}     = undef;

        my $ua = LWP::UserAgent->new();
        my $slapbird_response;

        $slapbird_response = $ua->post(
            $SLAPBIRD_APM_URI,
            'Content-Type'   => 'application/json',
            'x-slapbird-apm' => $self->key,
            Content          => encode_json( \%response )
        );

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

    }
    catch {
        Carp::carp(
'Unable to communicate with Slapbird, this request has not been tracked got error: '
              . $_ );
        POSIX::_exit(0);
    };

# We have to use POSIX::_exit(0) instead of exit(0) to not destroy database handles.
    return POSIX::_exit(0);
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
    my $queries    = [];
    my $dbi_tracer = SlapbirdAPM::Plack::DBIx::Tracer->new(
        sub {
            my %args = @_;
            push @$queries, { sql => $args{sql}, total_time => $args{time} };
        }
    );

    my $end_time = time * 1_000;

    try {
        $plack_response = $self->app->($env)
    }
    catch {
        $error = $_;
    };

    try {
        if ( ref($plack_response) && ref($plack_response) eq 'ARRAY' ) {
            $response = Plack::Response->new(@$plack_response);
            $self->_call_home( $request, $response,
                $env, $start_time, $end_time, $queries, $error );
            return $response->finalize;
        }
        else {
            return $self->response_cb(
                $plack_response,
                sub {
                    my $res = shift;
                    $response = Plack::Response->new(@$res);
                    $self->_call_home( $request, $response,
                        $env, $start_time, $end_time, $queries, $error );
                }
            );
        }

        if ($error) {
            Carp::croak($error);
        }
    }
    catch {
        Carp::croak($_);
    };
}

1;

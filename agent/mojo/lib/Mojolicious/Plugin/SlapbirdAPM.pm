package Mojolicious::Plugin::SlapbirdAPM;

use strict;
use warnings;

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::UserAgent;
use Mojo::IOLoop;
use Time::HiRes qw(time);
use Try::Tiny;
use Const::Fast;
use Carp;
use IPC::Open2;
use SlapbirdAPM::Trace;
use System::Info;
use namespace::clean;

$Carp::Internal{__PACKAGE__} = 1;

const my $SLAPBIRD_APM_URI => $ENV{SLAPBIRD_APM_DEV}
  ? $ENV{SLAPBIRD_APM_URI} . '/apm'
  : 'https://slapbirdapm.com/apm';
const my $SLAPBIRD_APM_NAME_URI => $ENV{SLAPBIRD_APM_DEV}
  ? $ENV{SLAPBIRD_APM_URI} . '/apm/name'
  : 'https://slapbirdapm.com/apm/name';
const my $UA => Mojo::UserAgent->new();

my $should_request = 1;
my $next_timestamp;

sub _call_home {
    my ( $json, $key, $app, $quiet ) = @_;
    return $UA->post_p(
        $SLAPBIRD_APM_URI,
        { 'x-slapbird-apm' => $key },
        json => $json
    )->then(
        sub {
            my ($res) = @_;
            my $result = $res->result;
            if ( !$result->is_success ) {
                if ( $result->code eq 429 ) {
                    $should_request = 0;
                    my $t = time;
                    $next_timestamp = $t + ( 86400 - $t );
                    $app->log->warn(
"You've hit your maximum number of requests for today. Please visit slapbirdapm.com to upgrade your plan."
                    ) unless $quiet;
                    return;
                }
                $app->log->warn(
'Unable to communicate with Slapbird, this request has not been tracked: '
                      . $json->{request_id}
                      . ' got status code '
                      . $result->code );
            }
        }
    )->catch(
        sub {
            $app->log->warn(
'Unable to communicate with Slapbird, this request has not been tracked: '
                  . $json->{request_id}
                  . ' got error '
                  . shift );
        }
    );
}

sub _enable_mojo_ua_tracking {
    my ($name) = @_;

    ## no critic []
    no strict 'refs';

    my $new = \&Mojo::UserAgent::new;

    *{'Mojo::UserAgent::new'} = sub {
        my $ua = $new->(@_);

        $ua->on(
            start => sub {
                my ( $ua, $tx ) = @_;
                $tx->req->headers->header( 'x-slapbird-name' => $name )
                  if $name;
            }
        );

        return $ua;
    };

    return;
}

sub register {
    my ( $self, $app, $conf ) = @_;
    my $key             = $conf->{key} // $ENV{SLAPBIRDAPM_API_KEY};
    my $topology        = exists $conf->{topology} ? $conf->{topology} : 1;
    my $ignored_headers = $conf->{ignored_headers};
    my $no_trace        = $conf->{no_trace};
    my $quiet           = $conf->{quiet};
    my $stack           = [];
    my $in_request      = 0;

    Carp::croak(
'Please provide your SlapbirdAPM key via the SLAPBIRD_APM_API_KEY env variable, or as part of the plugin declaration'
    ) if !$key;

    $app->routes->get(
        '/slapbird/health_check' => sub { shift->render( text => 'OK' ) } );

    $app->hook(
        around_dispatch => sub {
            my ( $next, $c ) = @_;

            if ( $next_timestamp && ( $next_timestamp >= time ) ) {
                $should_request = 1;
                undef $next_timestamp;
            }

            if ( !$should_request ) {
                $in_request = 0;
                $next->();
                return 1;
            }

            my $start_time      = time * 1_000;
            my $controller_name = ref($c);
            my $error;

            $in_request = 1;

            try {
                $stack = [];
                $next->();
            }
            catch {
                $error = $_;
            };

            my $end_time = time * 1_000;

            my $response_headers = $c->res->headers->to_hash;
            my $request_headers  = $c->req->headers->to_hash;

            for (@$ignored_headers) {
                delete $response_headers->{$_};
                delete $request_headers->{$_};
            }

            my $res = _call_home(
                {
                    type             => 'mojo',
                    method           => $c->req->method,
                    end_point        => $c->req->url->to_abs->path,
                    start_time       => $start_time,
                    end_time         => $end_time,
                    response_code    => $c->res->code ? $c->res->code : 500,
                    response_size    => $c->res->headers->content_length,
                    response_headers => $c->res->headers->to_hash,
                    request_id       => $c->req->request_id,
                    request_size     => $c->req->headers->content_length,
                    request_headers  => $c->req->headers->to_hash,
                    error            => $error,
                    requestor => $c->req->headers->header('x-slapbird-name')
                      // 'UNKNOWN',
                    handler => $controller_name,
                    stack   => $stack,
                    os      => System::Info->new->os
                },
                $key, $app, $quiet
            );

            $in_request = 0;

            die $error if $error;

            return 1;
        }
    );

    my $name;
    try {
        $name =
          Mojo::UserAgent->new->get(
            $SLAPBIRD_APM_NAME_URI => { 'x-slapbird-apm' => $key } )->result()
          ->json()->{name};
        _enable_mojo_ua_tracking($name) if $topology;
    }
    catch {
        chomp( my $msg = '' . $_ );
        $app->log->warn(
'Unable to communicate with slapbird for service name. Service topology will not work for this application: '
              . $msg )
          if $topology;
    };

    return if $no_trace;

    $app->hook(
        before_server_start => sub {
            $Carp::Verbose = 1;
            SlapbirdAPM::Trace->callback(
                sub {
                    my ( $name, $args, $sub ) = @_;

                    if ( !$in_request ) {
                        return $sub->(@$args);
                    }

                    my @ret;
                    my $start_time = time * 1_000;
                    try {
                        @ret = ( $sub->(@$args) );
                    }
                    catch {
                        Carp::croak($_);
                    };
                    my $end_time = time * 1_000;

                    push @$stack,
                      {
                        name       => $name,
                        start_time => $start_time,
                        end_time   => $end_time
                      };

                    return wantarray ? @ret : $ret[0];
                }
            );

            my @modules = (
                qw(
                  Mojolicious Mojolicious::Controller Mojo::UserAgent
                  Mojo::Base Mojo::File Mojo::Exception Mojo::IOLoop
                  Mojo::Pg Mojo::mysql Mojo::SQLite Mojo::JSON
                  Mojo::Server DBI DBD::Pg DBD::mysql
                ), @{ $conf->{trace_modules} // [] }
            );
            my @usable_modules = (qw(main));

            for (@modules) {
                eval("use $_");

                if ($@) {
                    next;
                }
                else {
                    push @usable_modules, $_;
                }
            }

            SlapbirdAPM::Trace->trace_pkgs(@usable_modules);
            SlapbirdAPM::Trace->trace_subs( 'CORE::sort', 'CORE::map',
                'CORE::grep', 'CORE::' );
        }
    );

    $app->log->info('Slapbird configured and active on this application.');
}

1;

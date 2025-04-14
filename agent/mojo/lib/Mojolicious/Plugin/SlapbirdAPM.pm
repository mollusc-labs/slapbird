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
use SlapbirdAPM::DBIx::Tracer;
use POSIX ();
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
my $in_request = 0;

sub _call_home {
    my ( $json, $key, $app, $quiet ) = @_;
    try {
        my $result = $UA->post(
            $SLAPBIRD_APM_URI,
            { 'x-slapbird-apm' => $key },
            json => $json
        )->result;
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
        }
    }
    catch {
        $app->log->warn(
'Unable to communicate with Slapbird, this request has not been tracked: '
              . $json->{request_id}
              . ' got error '
              . shift );

    }
}

{

    package Mojolicious::Plugin::SlapbirdAPM::Tracer;
    use Time::HiRes qw(time);

    sub new {
        my ( $class, %args ) = @_;
        return bless \%args, $class;
    }

    sub DESTROY {
        my ($self) = @_;
        my $stack = delete $self->{stack};
        push @$stack, { %$self, end_time => time * 1_000 };
    }

    1;
}

sub register {
    my ( $self, $app, $conf ) = @_;
    my $key             = $conf->{key} // $ENV{SLAPBIRDAPM_API_KEY};
    my $topology        = exists $conf->{topology} ? $conf->{topology} : 1;
    my $ignored_headers = $conf->{ignored_headers};
    my $no_trace        = $conf->{no_trace};
    my $quiet           = $conf->{quiet};
    my $stack           = [];

    Carp::croak(
'Please provide your SlapbirdAPM key via the SLAPBIRDAPM_API_KEY env variable, or as part of the plugin declaration'
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

            $stack = [];
            my $queries = [];

            try {
                my $tracer = SlapbirdAPM::DBIx::Tracer->new(
                    sub {
                        my %args = @_;
                        if ($in_request) {
                            push @$queries,
                              { sql => $args{sql}, total_time => $args{time} };
                        }
                    }
                );

                $next->();
            }
            catch {
                $error = $_;
            };

            my $end_time = time * 1_000;

            my $pid = fork();
            return 1 if $pid;

            my $response_headers = $c->res->headers->to_hash;
            my $request_headers  = $c->req->headers->to_hash;

            for (@$ignored_headers) {
                delete $response_headers->{$_};
                delete $request_headers->{$_};
            }

            _call_home(
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
                    handler     => $controller_name,
                    stack       => $stack,
                    os          => System::Info->new->os,
                    queries     => $queries,
                    num_queries => scalar @$queries
                },
                $key, $app, $quiet
            );

            $in_request = 0;

            die $error if $error;

            return POSIX::_exit(0);
        }
    );

    my $name;
    try {
        my $result =
          Mojo::UserAgent->new->get(
            $SLAPBIRD_APM_NAME_URI => { 'x-slapbird-apm' => $key } )->result();

        Carp::croak('API key invalid!') if ( !$result->is_success );

        $name = $result->json()->{name};

        # _enable_mojo_ua_tracking($name) if $topology;
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

                    my $tracer = Mojolicious::Plugin::SlapbirdAPM::Tracer->new(
                        name       => $name,
                        start_time => time * 1_000,
                        stack      => $stack
                    );

                    try {
                        return $sub->(@$args);
                    }
                    catch {
                        Carp::croak($_);
                    };
                }
            );

            my @modules = (
                qw(
                  Mojolicious Mojolicious::Controller Mojo::UserAgent
                  Mojo::Base Mojo::File Mojo::Exception Mojo::IOLoop
                  Mojo::Pg Mojo::mysql Mojo::SQLite Mojo::JSON
                  Mojo::Server DBI DBI::db DBI::st DBI::DBD DBD::Pg DBD::mysql DBIx::Classs
                  DBIx::Class::ResultSet DBIx::Class::Result
                ), @{ $conf->{trace_modules} // [] }
            );

            SlapbirdAPM::Trace->trace_pkgs(@modules);
        }
    );

    $app->log->info('Slapbird configured and active on this application.');
}

1;

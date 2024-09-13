package Dancer2::Plugin::SlapbirdAPM;

use strict;
use warnings;

use LWP::UserAgent              ();
use Const::Fast                 qw(const);
use SlapbirdAPM::Dancer2::Trace ();
use Time::HiRes                 qw(time);
use Try::Tiny;
use JSON::MaybeXS ();
use Dancer2::Plugin;
use LWP::UserAgent;
use System::Info;
use SlapbirdAPM::Dancer2::DBIx::Tracer;
use POSIX;
use feature 'say';

our $VERSION = $SlapbirdAPM::Agent::Dancer2::VERSION;

$Carp::Internal{__PACKAGE__} = 1;

const my $OS => System::Info->new->os;

const my $SLAPBIRD_APM_URI => $ENV{SLAPBIRD_APM_DEV}
  ? $ENV{SLAPBIRD_APM_URI} . '/apm'
  : 'https://slapbirdapm.com/apm';

has key => (
    is      => 'ro',
    default => sub { $_[0]->config->{key} // $ENV{SLAPBIRDAPM_API_KEY} }
);

has topology => (
    is      => 'ro',
    default => sub { $_[0]->config->{topology} // 1 }
);

has quiet => (
    is      => 'ro',
    default => sub { $_[0]->config->{quiet} // 0 }
);

has trace => (
    is      => 'ro',
    default => sub { $_[0]->config->{trace} // 1 }
);

has ignored_headers => (
    is      => 'ro',
    default => sub { $_[0]->config->{ignored_headers} // [] }
);

has trace_modules => (
    is      => 'ro',
    default => sub { $_[0]->config->{trace_modules} // [] }
);

has _ua => (
    is      => 'ro',
    default => sub { return LWP::UserAgent->new( timeout => 5 ) }
);

my $queries        = [];
my $in_request     = 0;
my $should_request = 0;

SlapbirdAPM::Dancer2::DBIx::Tracer->trace(
    sub {
        my %args = @_;
        if ($in_request) {
            push @$queries, { sql => $args{sql}, total_time => $args{time} };
        }
    }
);

{

    package Dancer2::Plugin::SlapbirdAPM::Tracer;

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

sub _unfold_headers {
    my ( $self, $headers ) = @_;
    $headers->remove_header( $self->ignored_headers->@* );
    my %headers = ( $headers->psgi_flatten->@* );
    return \%headers;
}

sub _call_home {
    my ( $self, $dancer2_request, $dancer2_response, $start_time,
        $end_time, $stack, $error )
      = @_;

    my $pid = fork();
    return if $pid;

    my %response;
    $response{type}          = 'dancer2';
    $response{method}        = $dancer2_request->method;
    $response{end_point}     = $dancer2_request->path;
    $response{start_time}    = $start_time;
    $response{end_time}      = $end_time;
    $response{response_code} = $dancer2_response->status;
    $response{response_headers} =
      $self->_unfold_headers( $dancer2_response->headers );
    $response{response_size} = $dancer2_response->header('Content-Length');
    $response{request_id}    = undef;
    $response{request_size}  = $dancer2_request->header('Content-Length');
    $response{request_headers} =
      $self->_unfold_headers( $dancer2_request->headers );
    $response{error} = $error;
    $response{error} //= undef;
    $response{os}          = $OS;
    $response{requestor}   = $dancer2_request->header('x-slapbird-name');
    $response{handler}     = undef;
    $response{stack}       = $stack;
    $response{num_queries} = scalar @$queries;
    $response{queries}     = $queries;

    my $ua = LWP::UserAgent->new();
    my $slapbird_response;

    try {
        $slapbird_response = $ua->post(
            $SLAPBIRD_APM_URI,
            'Content-Type'   => 'application/json',
            'x-slapbird-apm' => $self->key,
            Content          => JSON::MaybeXS::encode_json( \%response )
        );
    }
    catch {
        say STDERR
'Unable to communicate with Slapbird, this request has not been tracked got error: '
          . $_
          unless $self->quiet;
        exit 0;
    };

    if ( !$slapbird_response->is_success ) {
        if ( $slapbird_response->code eq 429 ) {
            say STDERR
"You've hit your maximum number of requests for today. Please visit slapbirdapm.com to upgrade your plan."
              unless $self->quiet;
            exit 0;
        }
        say STDERR
'Unable to communicate with Slapbird, this request has not been tracked got status code '
          . $slapbird_response->code
          unless $self->quiet;
    }

# We need to use POSIX::_exit(0) to not destroy database handles from the parent.
    POSIX::_exit(0);
}

sub BUILD {
    my ($self) = @_;

    if ( not defined $self->key ) {
        say STDERR
'No SlapbirdAPM API key set, set the SLAPBIRDAPM_API_KEY environment variable, or set key in the plugin properties';
        return;
    }

    my $stack = [];

    if ( $self->trace ) {
        SlapbirdAPM::Dancer2::Trace->callback(
            sub {
                my %args = @_;

                my $name = $args{name};
                my $sub  = $args{sub};
                my $args = $args{args};

                if ( !$in_request ) {
                    return $sub->(@$args);
                }

                my $tracer = Dancer2::Plugin::SlapbirdAPM::Tracer->new(
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
            qw(Dancer2 Dancer2::Core Dancer2::Core::App),
            @{ $self->trace_modules }
        );

        SlapbirdAPM::Dancer2::Trace->trace_pkgs(@modules);
    }

    my $request;
    my $start_time;
    my $end_time;
    my $error;
    $self->app->add_hook(
        Dancer2::Core::Hook->new(
            name => 'before',
            code => sub {
                $start_time = time * 1_000;
                my ($app) = @_;
                $in_request = 1;
                $stack      = [];
                $queries    = [];
                $request    = $app->request;
            }
        )
    );

    $self->app->add_hook(
        Dancer2::Core::Hook->new(
            name => 'on_route_exception',
            code => sub {
                ( undef, $error ) = @_;
            }
        )
    );

    $self->app->add_hook(
        Dancer2::Core::Hook->new(
            name => 'before_error',
            code => sub {
                $error = shift->message;
            }
        )
    );

    $self->app->add_hook(
        Dancer2::Core::Hook->new(
            name => 'after_error',
            code => sub {
                return unless $in_request;
                $end_time = time * 1_000;
                my ($response) = @_;
                $self->_call_home(
                    $request,  $response, $start_time,
                    $end_time, $stack,    $error
                );
                $in_request = 0;
            }
        )
    );

    $self->app->add_hook(
        Dancer2::Core::Hook->new(
            name => 'after',
            code => sub {
                return unless $in_request;
                $end_time = time * 1_000;
                my ($response) = @_;
                $self->_call_home( $request, $response, $start_time,
                    $end_time, $stack, undef );
                $in_request = 0;
            }
        )
    );

    return $self;
}

1;

package SlapbirdAPM::Agent::CGI;

use strict;
use warnings;

use Carp;
use CGI;
use LWP::UserAgent;
use POSIX ();
use SlapbirdAPM::CGI::DBIx::Tracer;
use IO::String;
use IO::Tee;
use IO::Pipe;
use Time::HiRes;
use HTTP::Request;
use HTTP::Response;
use System::Info;
use JSON;

$Carp::Internal{__PACKAGE__} = 1;

our $VERSION = '0.01';

my %request_headers;
my $cgi = CGI->new();
my $res = IO::String->new;
my $handler;
my $start_time;
my @error;
my @queries;
pipe( my $reader, my $writer );
my $orig_stdout = *STDOUT{IO};
my $key;

sub import {
    $start_time = time * 1_000;
    ($handler) = caller;
    SlapbirdAPM::CGI::DBIx::Tracer->new(
        sub {
            my %args = @_;
            push @queries, { sql => $args{sql}, total_time => $args{time} };
        }
    );
    %request_headers = map { $_ => $cgi->http($_) } $cgi->http();
    local *tee = IO::Tee->new( $writer, *STDOUT{IO} );

    *{STDOUT} = *tee;

    $SIG{__DIE__} = sub {
        @error = @_;
    };

    $key = $ENV{SLAPBIRDAPM_API_KEY};

    if ( !$key ) {
        Carp::carp(
"Your SlapbirdAPM key is not set, set the SLAPBIRDAPM_API_KEY environment variable."
        );
    }

    return;
}

END {
    my $end_time = time * 1_000;

    close($writer);
    my $raw_response = do {
        local $/ = undef;
        <$reader>;
    };
    close($reader);

    *{STDOUT} = $orig_stdout;

    if ( $raw_response !~ /^HTTP\/\d+\s\d+\s[A-Za-z].*/mxi ) {
        if ( !@error ) {
            $raw_response = "HTTP/1.1 200 OK\r\n$raw_response";
        }
        else {
            $raw_response =
              "HTTP/1.1 500 Internal Server Error\r\n$raw_response";
        }
    }

    local $SIG{CHLD} = 'IGNORE';
    if ( my $pid = fork() ) {
        return;
    }

    my $res = HTTP::Response->parse($raw_response);

    my $slapbird_hash = {
        type       => 'cgi',
        method     => $ENV{REQUEST_METHOD},
        end_point  => $cgi->url( -path_info => 1, -query => 1, -absolute => 1 ),
        start_time => $start_time,
        end_time   => $end_time,
        response_code => $res->code,
        response_size => $res->header('content-length')
          // length( $res->content ) // 0,
        response_headers => +{ $res->headers->flatten() },
        request_headers  => \%request_headers,
        error            => join( "\n", @error ),
        requestor        => $request_headers{HTTP_X_SLAPBIRD_NAME} // 'UNKNOWN',
        handler          => $handler,
        stack => undef,    # We don't trace stacks in CGI, because the overhead
        os          => System::Info->new->os,
        queries     => \@queries,
        num_queries => scalar @queries
    };

    my $ua = LWP::UserAgent->new();

    my $uri =
        $ENV{SLAPBIRD_APM_URI}
      ? $ENV{SLAPBIRD_APM_URI} . '/apm'
      : 'https://slapbirdapm.com/apm';

    my $sb_request = HTTP::Request->new( POST => $uri );
    $sb_request->content_type('application/json');
    $sb_request->content( encode_json($slapbird_hash) );
    my $result = $ua->request($sb_request);

    if ( !$result->is_success ) {
        Carp::carp( "Unable to communicate with Slapbird, got status code: "
              . $result->code );
    }

    POSIX::_exit(0);
}

1;

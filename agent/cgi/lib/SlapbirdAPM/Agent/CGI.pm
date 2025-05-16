package SlapbirdAPM::Agent::CGI;

use strict;
use warnings;

use Carp;
use CGI;
use LWP::UserAgent;
use POSIX ();
use SlapbirdAPM::CGI::DBIx::Tracer;
use IO::Tee;
use IO::Pipe;
use Time::HiRes;
use HTTP::Request;
use HTTP::Response;
use System::Info;
use JSON;

$Carp::Internal{__PACKAGE__} = 1;

our $VERSION = '0.05';

my %request_headers;
our $cgi = CGI->new();
our $handler;
our $start_time;
our @error;
our $queries = [];
our $key;
pipe( our $reader, our $writer );

SlapbirdAPM::CGI::DBIx::Tracer->new(
    sub {
        my %args = @_;
        push @$queries, { sql => $args{sql}, total_time => $args{time} };
    }
);

sub import {
    $key = $ENV{SLAPBIRDAPM_API_KEY};

    if ( !$key ) {
        warn(
"Your SlapbirdAPM key is not set, set the SLAPBIRDAPM_API_KEY environment variable to use SlapbirdAPM."
        );
        return;
    }

    $start_time = time * 1_000;
    ($handler) = caller;
    %request_headers = map { $_ => $cgi->http($_) } $cgi->http();
    local *tee = IO::Tee->new( $writer, *STDOUT{IO} );

    *{OLD_STDOUT} = *STDOUT{IO};
    *{STDOUT}     = *tee;

    $SIG{__DIE__} = sub {
        @error = @_;
    };

    return;
}

END {
    if ( !$key ) {
        close($writer);
        close($reader);
        return;
    }

    my $end_time = time * 1_000;

    close($writer);
    my $raw_response = do {
        local $/ = undef;
        <$reader>;
    };
    close($reader);

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

    if ( fork() ) {
        return;
    }

    my $res = HTTP::Response->parse($raw_response);

    my $slapbird_hash = {
        type       => 'cgi',
        method     => $ENV{REQUEST_METHOD},
        end_point  => $cgi->url( -path_info => 1, -query => 1, -absolute => 1 ),
        start_time => $start_time,
        end_time   => $end_time,
        response_code => +$res->code,
        response_size => $res->header('content-length')
          // length( $res->content ) // 0,
        response_headers => +{ $res->headers->flatten() },
        request_headers  => \%request_headers,
        request_size     => $request_headers{HTTP_CONTENT_LENGTH} // 0,
        error            => join( "\n", @error ),
        requestor        => $request_headers{HTTP_X_SLAPBIRD_NAME} // 'UNKNOWN',
        handler          => $handler eq 'main' ? 'CGI' : $handler,
        stack       => [],  # We don't trace stacks in CGI, because the overhead
        os          => System::Info->new->os,
        queries     => $queries,
        num_queries => scalar @$queries
    };

    my $ua = LWP::UserAgent->new();

    my $uri =
        $ENV{SLAPBIRD_APM_URI}
      ? $ENV{SLAPBIRD_APM_URI} . '/apm'
      : 'https://slapbirdapm.com/apm';

    my $sb_request = HTTP::Request->new( POST => $uri );
    $sb_request->content_type('application/json');
    $sb_request->content( encode_json($slapbird_hash) );
    $sb_request->header( 'x-slapbird-apm' => $key );
    my $result = $ua->request($sb_request);

    if ( !$result->is_success ) {
        warn( "Unable to communicate with Slapbird, got status code: "
              . $result->code );
    }

    POSIX::_exit(0);
}

1;

=pod

=encoding utf8

=head1 NAME

SlapbirdAPM::Agent::CGI

The L<SlapbirdAPM|https://www.slapbirdapm.com> user-agent for L<CGI> applications.

=head1 SYNOPSIS

=over 2

=item *

Create an application on L<SlapbirdAPM|https://www.slapbirdapm.com>

=item *

Install this ie C<cpanm SlapbirdAPM::Agent::CGI>, C<cpan -I SlapbirdAPM::Agent::CGI>

=item *

Add C<use SlapbirdAPM::Agent::CGI> near the top of your L<CGI> script

=item *

Add your API key to your environment, in Apache that looks like: C<SetEnv SLAPBIRDAPM_API_KEY ...>

=item *

Restart your web-server

=back

=head1 EXAMPLE

    #!/usr/bin/env perl
    
    use strict;
    use warnings;
    
    use DBI;
    use SlapbirdAPM::Agent::CGI;
    use CGI;
    
    my $dbh = DBI->connect('dbi:SQLite:dbname=file.db', '', '');
    
    my $sth = $dbh->prepare(q[select time('now');]);
    $sth->execute();
    my $time     = $sth->fetch->[0];
    my $response = 'Hello World! It is ' . $time . " o'clock";
    
    my $cgi = CGI->new();
    
    print $cgi->header();
    print <<"END"
    <!DOCTYPE html>
    <html>
      <body>
        <p>$response</p>
      </body>
    </html>
    END

=head1 SEE ALSO

L<SlapbirdAPM::Agent::Plack>

L<SlapbirdAPM::Agent::Mojo>

L<SlapbirdAPM::Agent::Dancer2>

=head1 AUTHOR

Mollusc Software Solutions (formerly Mollusc Labs), C<https://github.com/mollusc-labs>

=head1 LICENSE

SlapbirdAPM::Agent::CGI like all SlapbirdAPM user-agents is licensed under the MIT license.

SlapbirdAPM (the website) however, is licensed under the GNU AGPL version 3.0.

=cut

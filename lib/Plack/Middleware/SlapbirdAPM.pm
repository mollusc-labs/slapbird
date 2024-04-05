package Plack::Middleware::SlapbirdAPM;

use parent qw( Plack::Middleware );
use Time::Piece;
use Try::Tiny;
use Plack::Request;
use Const::Fast;
use AnyEvent::HTTP;
use JSON::MaybeXS;
use Slapbird::DTO::HTTPTransaction;
use namespace::clean;

use Plack::Util::Accessor qw(key);

const my $SLAPBIRD_APM_URI => 'apm.slapbirdapm.com';

sub _call_home {
    my ( $dto, $key ) = @_;

    http_post(
        headers => {
            'x-slapbird-apm' => $key,
            'content-type'   => 'application/json'
        },
        body              => encode_json( $dto->as_hashref ),
        $SLAPBIRD_APM_URI => sub { }
    );
}

sub call {
    my ( $self, $env ) = @_;

    my $request = Plack::Request->new($env);
    return [ 200, [ 'Content-Type' => 'text/plain' ], 'OK' ]
      if $request->uri->path eq 'slapbird/health_check'
      || $request->uri->path eq '/slapbird/health_check';

    my $start_time = localtime->epoch();
    my $error;

    my $response;
    try {
        $response = $self->app->($env);
    }
    catch {
        $error = $_;
    };
    my $end_time = localtime->epoch();

    _call_home(
        Slapbird::DTO::HTTPTransaction->new(
            type          => 'plack',
            method        => $request->method,
            end_point     => $request->uri->path,
            start_time    => $start_time,
            end_time      => $end_time,
            response_code => $response->[0],
            response_size => undef,
            request_size  => $request->content_length,
            error         => $error
        ),
        $self->key
    );

    return $response;
}

1;

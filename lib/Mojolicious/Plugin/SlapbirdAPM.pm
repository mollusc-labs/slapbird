package Mojolicious::Plugin::SlapbirdAPM;

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::UserAgent;
use Mojo::IOLoop;
use Time::Piece;
use Try::Tiny;
use Slapbird::DTO::HTTPTransaction;
use Const::Fast;
use namespace::clean;

our $VERSION = 0.001;

const my $SLAPBIRD_APM_URI => 'apm.slapbirdapm.com';

sub _call_home {
    my ( $dto, $key ) = @_;
    state $ua = Mojo::UserAgent->new();
    $ua->post(
        $SLAPBIRD_APM_URI,
        { 'x-slapbird-apm' => $key },
        json => $dto->as_hashref()
    );
}

sub register {
    my ( $self, $app, $key ) = @_;

    $app->routes->get( '/slapbird/health_check' => sub { shift->render('OK') }
    );

    $app->hook(
        around_dispatch => sub {
            my ( $next, $c ) = @_;

            my $controller_name = ref($c);
            my $start_time      = localtime->epoch();
            my $error;

            try {
                $next->();
            }
            catch {
                $error = $_;
            }

            my $end_time = localtime->epoch();

            Mojo::IOLoop->next_tick(
                sub {
                    _call_home(
                        Slapbird::DTO::HTTPTransaction->new(
                            type          => 'mojo',
                            method        => $c->req->method,
                            end_point     => $c->req->url->to_abs->path,
                            start_time    => $start_time,
                            end_time      => $end_time,
                            response_code => $c->res->code,
                            response_size => $c->res->headers->content_length,
                            request_id    => $c->req->request_id,
                            request_size  => $c->req->headers->content_length,
                            error         => $error
                        ),
                        $key
                    );
                }
            );

            return 1;
        }
    );
}

1;

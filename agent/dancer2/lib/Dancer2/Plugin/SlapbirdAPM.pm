package Dancer2::Plugin::SlapbirdAPM;

use strict;
use warnings;

use Dancer2::Plugin;
use Carp            ();
use Types::Standard qw(Str ArrayRef Bool Int);
use AnyEvent;
use AnyEvent::HTTP;
use namespace::clean;

$Carp::Internal{__PACKAGE__} = 1;

has key => (
    is       => 'ro',
    isa      => Str,
    default  => sub { $ENV{SLAPBIRDAPM_API_KEY} },
    required => 1
);

has topology => (
    is      => 'ro',
    isa     => Bool,
    default => sub { 0 }
);

has ignored_headers => (
    is      => 'ro',
    isa     => ArrayRef,
    default => sub { [] }
);

sub BUILD {
    my ($self) = @_;

    CORE::say 'Hello World!';

    $self->app->add_hook(
        Dancer2::Core::Hook->new(
            name => 'after',
            code => sub {
                use DDP;
                p @_;
            }
        )
    );
}

1;

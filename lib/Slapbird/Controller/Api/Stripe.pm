package Slapbird::Controller::Api::Stripe;

use Mojo::Base 'Mojolicious::Controller';
use Const::Fast;

const my $STRIPE_WEBHOOK_SECRET => $ENV{STRIPE_WEBHOOK_SECRET};

sub webhook {
  my ($c) = @_;

  # TODO: (rf) We need a way to handle webhooks.
}

1;

package Slapbird::Controller::Htmx::Pricing;

use Mojo::Base 'Mojolicious::Controller';

use strict;
use warnings;

sub htmx_pricing {
  my ($c) = @_;

  my @prices = $c->resultset('PricingPlan')->search({active => 1})->all;

  return $c->render(template => 'htmx/_pricing', prices => \@prices);
}

1;
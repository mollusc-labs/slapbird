package Slapbird::Controller::Api::Dashboard;

use Mojo::Base 'Mojolicious::Controller';

use strict;
use warnings;
use Slapbird::Advice::ErrorAdvice;

sub json_graph {
  my ($c) = @_;

  my ($from_time, $to_time) = $c->get_from_to_time();

  my @transactions = $c->resultset('HTTPTransaction')->search(
    {
      application_id => $c->application_context->application_id,
      start_time     => {-between => [$from_time, $to_time]}
    },
    {order_by => {-asc => 'start_time'}}
  )->all;

  if (scalar(@transactions) == 0) {
    return $c->render(
      status => 409,
      json   => {message => 'No transactions for this time period'}
    );
  }

  @transactions = map { $_->to_graph_dto() } @transactions;

  return $c->render(json => \@transactions);
}

1;
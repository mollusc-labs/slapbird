package Slapbird::Controller::Api::Apm;

use Mojo::Base 'Mojolicious::Controller';
use Slapbird::Sanitizer::HTTPTransaction;
use Slapbird::Validator::HTTPTransaction;
use Slapbird::Advice::ErrorAdvice;
use Carp;

# TODO: (RF) this needs to be refactored to use the new actions api.
sub call {
  my ($c) = @_;

  my $api_key = $c->apm_application_context || return $c->render(
    status => 401,
    json   => Slapbird::Advice::ErrorAdvice->new(
      errors => [{apm_key => ['You are not authorized to view this route.']}]
    )->to_hashref()
  );

  my $count = $c->cache->get($api_key->application_id);
  if (defined $count) {
    if ($count
      > $api_key->application->user_pricing_plan->pricing_plan->max_requests)
    {
      return $c->render(
        status => 429,
        json   => [{error => 'Your plan has made too many requests.'}]
      );
    }
  }
  else {
    # Store for one day
    $c->cache->set($api_key->application_id, 0, 86_400);
  }

  my $transaction = $c->req->json();
  my @errors = Slapbird::Validator::HTTPTransaction->validate($transaction);

  if (@errors) {
    return $c->render(
      status => 400,
      json   =>
        Slapbird::Advice::ErrorAdvice->new(errors => \@errors)->to_hashref()
    );
  }

  $transaction->{application_id} = $api_key->application_id;

  $c->cache->incr($api_key->application_id, 1);

# TODO: (RF) This should use Minion, so we dont make user applications wait
# for us to complete the sanitization/validation process. There is a Minion plugin
# for Mojo but it has some issues. Perhaps we run a Minion instance, or we may also
# want to use RabbitMQ + another Mojo service for sanitization and rely on "eventually consistent"
# HTTP transactions.

# Ideally this is just $c->minion->enqueue(sub { ... }); $c->render(json => { happy })
  return $c->render(
    json => $c->actions->add_http_transaction(http_transaction => $transaction),
    status => 201
  );
}

sub name {
  my ($c) = @_;

  my $application_name = $c->apm_application_context->name
    or Carp::croak('Somehow called /apm/name without an apm_key??');

  return $c->render(
    status => 404,
    json   => Slapbird::Advice::ErrorAdvice->new(
      errors => {apm_key => ['No app associated with apm key.']}
    )->to_hashref()
  ) if !$application_name;

  return $c->render(json => {name => $application_name}, status => 200);
}

1;
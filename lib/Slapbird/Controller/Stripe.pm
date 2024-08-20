package Slapbird::Controller::Stripe;

use Mojo::Base 'Mojolicious::Controller';
use Slapbird::Client::Stripe;
use Const::Fast;
use feature 'state';

const my $stripe_client => Slapbird::Client::Stripe->new();

sub portal {
  my ($c) = @_;
  my $customer_stripe_id = $c->user->stripe_id;

  if (!$customer_stripe_id) {
    return $c->redirect_to('/dashboard');
  }

  my $session_result
    = $stripe_client->create_billing_session($customer_stripe_id)->result;

  unless ($session_result->is_success) {
    $c->debug($session_result);
    $c->flash_danger(
      'Something went wrong loading your billing details, please try again later.'
    );
    return $c->redirect_to('/dashboard/manage-plan');
  }

  my $session_json = $session_result->json;
  return $c->redirect_to($session_json->{url});
}

sub checkout_session {
  my ($c) = @_;

  return $c->redirect_to('/dashboard/manage-plan') if $c->user->is_associated;

  my $price_id = $c->param('price_id');

  return $c->render(status => 400, template => 'util/bad_request')
    if !$price_id;

  my $customer_stripe_id = $c->user->stripe_id;
  my $error;
  if (!$customer_stripe_id) {
    ($customer_stripe_id, $error)
      = $c->actions->create_stripe_customer_for_user(
      user_id => $c->user->user_id);
  }

  if ($error) {
    $c->flash_danger(
      'Something went wrong connecting to Stripe, please try again later.');
    $c->redirect_to('/dashboard/manage-plan');
  }

  my $session_result = $stripe_client->create_checkout_session(
    $price_id,
    {
      mode                       => 'subscription',
      billing_address_collection => 'required',
      customer                   => $customer_stripe_id,
      'customer_update[address]' => 'auto',
      'customer_update[name]'    => 'auto',
      client_reference_id        => $c->user->user_id
    }
  )->result;

  unless ($session_result->is_success) {
    $c->log->error($session_result->content);
    $c->debug($session_result);
    $c->flash_danger(
      'Something went wrong checking you out, please try again later.');
    return $c->redirect_to('/dashboard/manage-plan/upgrade');
  }

  my $session_json = $session_result->json;

  $c->debug($session_json);

  $c->session(plan_to_subscribe_to =>
      $c->resultset('PricingPlan')->find({stripe_id => $price_id})
      ->pricing_plan_id);

  return $c->redirect_to($session_json->{url});
}

sub checkout_session_success {
  my ($c) = @_;

  if (!$c->user->stripe_id) {
    $c->flash_danger('Something went wrong subscribing to that plan');
    $c->redirect_to('/dashboard/manage-plan');
  }

  my $pricing_plan_id = $c->session('plan_to_subscribe_to');

  if (!$pricing_plan_id) {
    $c->flash_danger('Something went wrong subscribing to that plan');
    $c->log->error('Checkout session success called without proper values???');
    $c->redirect_to('/dashboard/manage-plan');
  }

  if (my $id_to_cancel = $c->user->user_pricing_plan->stripe_id) {
    $c->stripe->subscriptions(
      cancel => {id => $id_to_cancel, customer => $c->user->stripe_id});
  }

  my $subscriptions
    = $c->stripe->subscriptions(list => $c->user->stripe_id)->data;

  $c->user->user_pricing_plan->update(
    {pricing_plan_id => $pricing_plan_id, stripe_id => $subscriptions->[0]->id}
  );

  $c->flash_success('Thank you for upgrading your SlapbirdAPM plan!');
  $c->redirect_to('/dashboard/manage-plan');
}

1;

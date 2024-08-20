package Slapbird::Controller::Static;

use Mojo::Base 'Mojolicious::Controller';

sub index {
  my ($c) = @_;
  return $c->redirect_to('/dashboard') if $c->logged_in;
  return $c->render(template => 'index');
}

sub pricing {
  my ($c) = @_;
  return $c->render(template => 'pricing');
}

sub privacy {
  my ($c) = @_;
  return $c->render(template => 'privacy');
}

sub tos {
  my ($c) = @_;
  return $c->render(template => 'tos');
}

sub getting_started {
  my ($c) = @_;
  return $c->render(template => 'getting_started');
}

sub upgrade {
  my ($c) = @_;

  my @pricing_plans
    = $c->resultset('PricingPlan')->search({stripe_id => {-not => undef}})->all;

  return $c->render(
    template           => 'upgrade',
    user_is_associated => $c->user->is_associated,
    user_pricing_plan  => $c->user->user_pricing_plan,
    pricing_plans      => [reverse @pricing_plans]
  );
}

sub docs {
  my ($c) = @_;
  return $c->render(template => 'documentation');
}

1;

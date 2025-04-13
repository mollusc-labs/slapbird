# This file is apart of SlapbirdAPM, a Free and Open-Source
# web application APM for Perl 5 web applications.
#
# Copyright (C) 2024  Mollusc Labs.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


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
    return $c->redirect_to('/dashboard/manage-plan');
  }

  my $addon = $c->resultset('Addon')->find({stripe_id => $price_id});
  my $pricing_plan
    = $c->resultset('PricingPlan')->find({stripe_id => $price_id});

  if (!$addon && !$pricing_plan) {
    $c->log->error("NO ADDON OR PRICING PLAN WITH STRIPE_ID $price_id");
    $c->flash_danger(
      'Something went wrong checking you out, please try again later.');
    return $c->redirect_to('/dashboard/manage-plan/upgrade');
  }

  my $subscribable_id = $addon ? $addon->id : $pricing_plan->id;
  my $context         = $addon ? 'addon'    : 'pricing_plan';

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

  $c->session(subscribable_id => $subscribable_id);
  $c->session(price_id        => $price_id);
  $c->session(stripe_context  => $context);

  return $c->redirect_to($session_json->{url});
}

sub checkout_session_success {
  my ($c) = @_;

  if (!$c->user->stripe_id) {
    $c->flash_danger('Something went wrong subscribing to that plan');
    $c->redirect_to('/dashboard/manage-plan');
  }

  my $context         = $c->session('stripe_context');
  my $subscribable_id = $c->session('subscribable_id');
  my $price_id        = $c->session('price_id');

  if (!$subscribable_id || !$context) {
    $c->flash_danger("Something went wrong subscribing to that $context");
    $c->log->error('Checkout session success called without proper values???');
    return $c->redirect_to('/dashboard/manage-plan');
  }

  my $subscriptions
    = $c->stripe->subscriptions(list => $c->user->stripe_id)->data;

  my $subscription_id;

  for my $sub (@$subscriptions) {
    for (@{$sub->items->data}) {
      if ($_->plan->id eq $price_id) {
        $subscription_id = $sub->id;
        last;
      }
    }

    last if ($subscription_id);
  }

  if (!$subscription_id) {
    $c->flash_danger("Something went wrong subscribing to that $context");
    $c->log->error('Checkout session success called without proper values???');
    $c->log->error(
      qq[Price ID: $price_id, Context: $context, Subscribable: $subscribable_id]
    );
    return $c->redirect_to('/dashboard/manage-plan');
  }

  if ($context eq 'pricing_plan') {
    if (my $id_to_cancel = $c->user->user_pricing_plan->stripe_id) {
      $c->stripe->subscriptions(
        cancel => {id => $id_to_cancel, customer => $c->user->stripe_id});
    }

    $c->user->user_pricing_plan->update({
      pricing_plan_id => $subscribable_id, stripe_id => $subscription_id
    });
  }

  if ($context eq 'addon') {
    $c->resultset('UserPricingPlanAddon')->create(
      {
        addon_id             => $subscribable_id,
        user_pricing_plan_id =>
          $c->user->user_pricing_plan->user_pricing_plan_id,
        stripe_id => $subscription_id
      }
    );
  }

  $c->flash_success(qq[Thank you for upgrading your SlapbirdAPM plan!]);
  return $c->redirect_to('/dashboard/manage-plan');
}

1;

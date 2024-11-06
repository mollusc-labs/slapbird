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


package Slapbird::Client::Stripe;

use Moo;
use Mojo::UserAgent;
use Carp ();
use Const::Fast;
use URL::Encode qw(url_encode);
use feature     qw(state);

const my $STRIPE_API_URI => 'https://api.stripe.com/v1';
const my $SUCCESS_CALLBACK_URI => $ENV{SLAPBIRD_PRODUCTION}
  ? 'https://slapbirdapm.com/dashboard/manage-plan/stripe/upgrade/success'
  : 'http://localhost:3000/dashboard/manage-plan/stripe/upgrade/success';
const my $CANCEL_CALLBACK_URI => $ENV{SLAPBIRD_PRODUCTION}
  ? 'https://slapbirdapm.com/dashboard/manage-plan/upgrade'
  : 'http://localhost:3000/dashboard/manage-plan/upgrade';
const my $BILLING_PORTAL_CALLBACK_URI => $ENV{SLAPBIRD_PRODUCTION}
  ? 'https://slapbirdapm.com/dashboard/manage-plan'
  : 'http://localhost:3000/dashboard/manage-plan';

has _ua =>
  (is => 'ro', default => sub { return state $ua = Mojo::UserAgent->new() });

sub retrieve_checkout_session_for_customer {
  my ($self, $customer_id) = @_;
  return $self->_ua->get(
    $STRIPE_API_URI . '/checkout/sessions/' . $customer_id,
    {
      Accepts       => 'application/json',
      Authorization => $self->_authorization_header
    }
  );
}

sub create_checkout_session {
  my ($self, $price_item, $extra_data) = @_;

  $extra_data //= {};

  return $self->_ua->post(
    $STRIPE_API_URI . '/checkout/sessions',
    {
      Authorization => $self->_authorization_header,
      Accepts       => 'application/json'
    },
    form => {
      billing_address_collection => 'auto',
      'line_items[0][price]'     => $price_item,
      'line_items[0][quantity]'  => 1,
      success_url                => $SUCCESS_CALLBACK_URI,
      cancel_url                 => $CANCEL_CALLBACK_URI,
      currency                   => 'USD',
      %$extra_data
    }
  );
}

sub create_billing_session {
  my ($self, $customer_id) = @_;
  return $self->_ua->post(
    $STRIPE_API_URI . '/billing_portal/sessions',
    {
      Authorization => $self->_authorization_header,
      Accepts       => 'application/json'
    },
    form =>
      {return_url => $BILLING_PORTAL_CALLBACK_URI, customer => $customer_id}
  );
}

sub list_subscriptions {
  my ($self, $payload) = @_;
  return $self->_ua->get(
    $STRIPE_API_URI . '/subscriptions',
    {
      Authorization => $self->_authorization_header,
      Accepts       => 'application/json'
    },
    form => $payload
  );
}

sub _authorization_header {
  Carp::croak(
    q{Can't create authorization header without STRIPE_API_KEY env variable.})
    unless exists $ENV{STRIPE_API_KEY};
  return 'Bearer ' . $ENV{STRIPE_API_KEY};
}

1;

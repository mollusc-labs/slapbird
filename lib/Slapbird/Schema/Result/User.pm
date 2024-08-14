package Slapbird::Schema::Result::User;

use base 'DBIx::Class::Core';
use strict;
use warnings;

__PACKAGE__->table('users');

__PACKAGE__->load_components(qw(InflateColumn::DateTime TimeStamp));

__PACKAGE__->add_columns(qw(
  name
  email
  oauth_id
  oauth_provider
  stripe_id
  role
  last_login
  receives_email
  first_login
));

__PACKAGE__->add_columns(
  user_id    => {is_auto_increment => 1},
  created_at => {data_type         => 'datetime', set_on_create => 1},
  updated_at =>
    {data_type => 'datetime', set_on_create => 1, set_on_update => 1}
);

__PACKAGE__->set_primary_key('user_id');
__PACKAGE__->has_one(
  _user_pricing_plan => 'Slapbird::Schema::Result::UserPricingPlan',
  'user_id'
);
__PACKAGE__->has_one(
  _associated_user_pricing_plan =>
    'Slapbird::Schema::Result::AssociatedUserPricingPlan',
  'user_id'
);

sub user_pricing_plan {
  my ($self) = @_;

  if ($self->_user_pricing_plan) {
    return $self->_user_pricing_plan;
  }

  return $self->_associated_user_pricing_plan->user_pricing_plan;
}

sub is_associated {
  my ($self) = @_;
  return $self->user_pricing_plan->user_id ne $self->user_id;
}

sub applications {
  my ($self) = @_;
  return $self->user_pricing_plan->applications;
}

1;

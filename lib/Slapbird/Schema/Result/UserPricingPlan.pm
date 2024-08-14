package Slapbird::Schema::Result::UserPricingPlan;

use base 'DBIx::Class::Core';
use strict;
use warnings;

__PACKAGE__->table('user_pricing_plans');

__PACKAGE__->load_components(qw(InflateColumn::DateTime TimeStamp));

__PACKAGE__->add_columns(qw(
  pricing_plan_id
  user_id
  is_active
));

__PACKAGE__->add_columns(
  user_pricing_plan_id => {is_auto_increment => 1},
  joined_at            => {data_type         => 'datetime', set_on_create => 1}
);

__PACKAGE__->set_primary_key('user_pricing_plan_id');
__PACKAGE__->has_many(
  associated_user_pricing_plans =>
    'Slapbird::Schema::Result::AssociatedUserPricingPlan',
  'user_pricing_plan_id'
);
__PACKAGE__->has_many(
  applications => 'Slapbird::Schema::Result::Application',
  'user_pricing_plan_id'
);
__PACKAGE__->has_many(
  associated_user_pricing_plans =>
    'Slapbird::Schema::Result::AssociatedUserPricingPlan',
  'user_pricing_plan_id'
);
__PACKAGE__->belongs_to(
  pricing_plan => 'Slapbird::Schema::Result::PricingPlan',
  'pricing_plan_id'
);
__PACKAGE__->belongs_to(user => 'Slapbird::Schema::Result::User', 'user_id');

sub users {
  my ($self) = @_;
  my @users = ($self->user,);

  for ($self->associated_user_pricing_plans) {
    push @users, $_->user;
  }

  return wantarray ? @users : \@users;
}

1;

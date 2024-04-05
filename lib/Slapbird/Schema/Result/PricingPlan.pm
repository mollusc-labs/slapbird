package Slapbird::Schema::Result::PricingPlan;

use base 'DBIx::Class::Core';
use strict;
use warnings;

__PACKAGE__->table('pricing_plans');
__PACKAGE__->load_components(qw(InflateColumn::DateTime TimeStamp));

__PACKAGE__->add_columns(qw(
  name
  description
  price
  price_pretty
  is_free
  pricing_plan_status
  max_requests
  max_users
  max_applications
  active
));

__PACKAGE__->add_columns(
  pricing_plan_id => {is_auto_increment => 1},
  created_at      => {data_type         => 'datetime', set_on_create => 1}
);

__PACKAGE__->set_primary_key('pricing_plan_id');
__PACKAGE__->has_many(user_pricing_plans => 'Slapbird::Schema::Result::UserPricingPlan', 'pricing_plan_id');

1;
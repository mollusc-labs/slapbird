package Slapbird::Schema::Result::AssociatedUserPricingPlan;

use base 'DBIx::Class::Core';
use strict;
use warnings;

__PACKAGE__->table('associated_user_pricing_plans');

__PACKAGE__->load_components(qw(InflateColumn::DateTime TimeStamp));

__PACKAGE__->add_columns(qw(
  user_pricing_plan_id
  user_id
));

__PACKAGE__->add_columns(
  associated_user_pricing_plan_id => {is_auto_increment => 1},
  joined_at                       => {data_type         => 'datetime', set_on_create => 1}
);

__PACKAGE__->set_primary_key('user_pricing_plan_id');
__PACKAGE__->belongs_to(user_pricing_plan => 'Slapbird::Schema::Result::UserPricingPlan', 'user_pricing_plan_id');
__PACKAGE__->belongs_to(user              => 'Slapbird::Schema::Result::User',            'user_id');

1;
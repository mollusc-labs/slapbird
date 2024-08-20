package Slapbird::Schema::Result::Card;

use base 'DBIx::Class::Core';
use strict;
use warnings;

__PACKAGE__->table('cards');
__PACKAGE__->load_components(qw(InflateColumn::DateTime TimeStamp));

__PACKAGE__->add_columns(qw(
  user_pricing_plan_id
  user_id
));

__PACKAGE__->add_columns(
  card_id    => {is_auto_increment => 1},
  ending_in  => {data_type         => 'varchar',  size          => 4},
  type       => {data_type         => 'varchar',  size          => 50},
  created_at => {data_type         => 'datetime', set_on_create => 1},
  updated_at =>
    {data_type => 'datetime', set_on_create => 1, set_on_update => 1}
);

__PACKAGE__->set_primary_key('card_id');
__PACKAGE__->belongs_to(
  user_pricing_plan => 'Slapbird::Schema::Result::UserPricingPlan',
  'user_pricing_plan_id'
);
__PACKAGE__->belongs_to(user => 'Slapbird::Schema::Result::User', 'user_id');

1;

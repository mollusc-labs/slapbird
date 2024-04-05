package Slapbird::Schema::Result::ApiKey;

use base 'DBIx::Class::Core';
use strict;
use warnings;

__PACKAGE__->table('api_keys');
__PACKAGE__->load_components(qw(InflateColumn::DateTime TimeStamp));

__PACKAGE__->add_columns(qw(
  application_id
  active
  user_id
));

__PACKAGE__->add_columns(
  api_key_id          => {is_auto_increment => 1},
  name                => {data_type         => 'varchar',  size          => 100},
  application_api_key => {data_type         => 'varchar',  size          => 126},
  created_at          => {data_type         => 'datetime', set_on_create => 1},
  updated_at          => {data_type         => 'datetime', set_on_create => 1, set_on_update => 1}
);

__PACKAGE__->set_primary_key('api_key_id');
__PACKAGE__->belongs_to(application => 'Slapbird::Schema::Result::Application', 'application_id');
__PACKAGE__->belongs_to(user        => 'Slapbird::Schema::Result::User',        'user_id');

1;
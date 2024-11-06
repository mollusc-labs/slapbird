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


package Slapbird::Schema::Result::Application;

use base 'DBIx::Class::Core';
use strict;
use warnings;

__PACKAGE__->table('applications');
__PACKAGE__->load_components(qw(InflateColumn::DateTime TimeStamp));

__PACKAGE__->add_columns(qw(
  user_pricing_plan_id
  user_id
));

__PACKAGE__->add_columns(
  application_id => {is_auto_increment => 1},
  name           => {data_type         => 'varchar',  size          => 100},
  slug           => {data_type         => 'varchar',  size          => 100},
  description    => {data_type         => 'varchar',  size          => 500},
  created_at     => {data_type         => 'datetime', set_on_create => 1},
  updated_at     =>
    {data_type => 'datetime', set_on_create => 1, set_on_update => 1}
);

__PACKAGE__->set_primary_key('application_id');
__PACKAGE__->has_many(
  api_keys => 'Slapbird::Schema::Result::ApiKey',
  'application_id'
);
__PACKAGE__->has_many(
  http_transactions => 'Slapbird::Schema::Result::HTTPTransaction',
  'application_id'
);
__PACKAGE__->belongs_to(
  user_pricing_plan => 'Slapbird::Schema::Result::UserPricingPlan',
  'user_pricing_plan_id'
);

__PACKAGE__->belongs_to(user => 'Slapbird::Schema::Result::User', 'user_id');

sub user_is_allowed {
  my ($self, $user_id) = @_;

  if ($self->user_pricing_plan->user_id eq $user_id) {
    return 1;
  }

  for ($self->user_pricing_plan->associated_user_pricing_plans->all) {
    return 1 if ($_->user_id eq $user_id);
  }

  return 0;
}

1;

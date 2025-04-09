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


package Slapbird::Schema::Result::UserPricingPlanAddon;

use base 'DBIx::Class::Core';
use strict;
use warnings;

__PACKAGE__->table('user_pricing_plan_addons');
__PACKAGE__->load_components(qw(InflateColumn::DateTime TimeStamp));

__PACKAGE__->add_columns(qw(
  addon_id
  user_pricing_plan_id
  stripe_id
));

__PACKAGE__->add_columns(
  user_pricing_plan_addon_id => {is_auto_increment => 1},
  joined_at                  => {data_type => 'datetime', set_on_create => 1}
);
__PACKAGE__->set_primary_key('user_pricing_plan_addon_id');

__PACKAGE__->belongs_to(
  user_pricing_plan => 'Slapbird::Schema::Result::UserPricingPlan',
  'user_pricing_plan_id'
);
__PACKAGE__->has_one(addon => 'Slapbird::Schema::Result::Addon', 'addon_id');

1;

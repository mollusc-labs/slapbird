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


package Slapbird::Schema::Result::UserPricingPlan;

use base 'DBIx::Class::Core';
use strict;
use warnings;

use Time::HiRes qw(time);

__PACKAGE__->table('user_pricing_plans');

__PACKAGE__->load_components(qw(InflateColumn::DateTime TimeStamp));

__PACKAGE__->add_columns(qw(
  pricing_plan_id
  user_id
  stripe_id
  on_hold
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
__PACKAGE__->has_many(
  addons => 'Slapbird::Schema::Result::UserPricingPlanAddon',
  'user_pricing_plan_addons'
);
__PACKAGE__->has_one(
  card => 'Slapbird::Schema::Result::Card',
  'user_pricing_plan_id'
);
__PACKAGE__->belongs_to(
  pricing_plan => 'Slapbird::Schema::Result::PricingPlan',
  'pricing_plan_id'
);
__PACKAGE__->belongs_to(user => 'Slapbird::Schema::Result::User', 'user_id');

sub addons {
  my ($self) = @_;

  my @addons = map { $_->addon } $self->user_pricing_plan_addons->all;

  return wantarray ? @addons : \@addons;
}

sub users {
  my ($self) = @_;
  my @users = ($self->user,);

  for ($self->associated_user_pricing_plans) {
    push @users, $_->user;
  }

  return wantarray ? @users : \@users;
}

sub is_refundable {
  my ($self) = @_;

  unless ($self->pricing_plan->price > 0) {
    return 0;
  }

  return $self->joined_at - (time * 1_000);
}

1;

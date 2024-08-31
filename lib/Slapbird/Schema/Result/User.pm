# This file is apart of SlapbirdAPM, a Free and Open-Source
# web application APM for Perl 5 web applications.
#
# Copyright (C) 2024  Mollusc Labs Inc.
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

sub associated_user_pricing_plan {
  my ($self) = @_;

  if (!$self->is_associated) {
    return undef;
  }

  return $self->_associated_user_pricing_plan;
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

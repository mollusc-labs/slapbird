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


package Slapbird::Action::AddUserToFreePlan;

use Moo;
use Try::Tiny;
use Slapbird::Action::AddUserToPricingPlan;

has schema  => (is => 'ro', required => 1);
has user_id => (is => 'ro', required => 1);

sub execute {
  my ($self) = @_;

  my $free_plan_id
    = $self->schema->resultset('PricingPlan')->find({price => 0, active => 1})
    ->pricing_plan_id;

  return Slapbird::Action::AddUserToPricingPlan->new(
    user_id         => $self->user_id,
    pricing_plan_id => $free_plan_id,
    schema          => $self->schema
  )->execute();
}

1;

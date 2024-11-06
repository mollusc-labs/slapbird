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


package Slapbird::Action::AddUserToPricingPlan;

use Moo;
use Types::Standard qw(Str);

has schema          => (is => 'ro', required => 1);
has user_id         => (is => 'ro', isa      => Str, required => 1);
has pricing_plan_id => (is => 'ro', isa      => Str, required => 1);

sub execute {
  my ($self) = @_;

  my $guard = $self->schema->txn_scope_guard;

  my $user_pricing_plan_rs = $self->schema->resultset('UserPricingPlan');
  my $associated_pricing_plan_rs
    = $self->schema->resultset('AssociatedUserPricingPlan');

  my $is_associated
    = $associated_pricing_plan_rs->find({user_id => $self->user_id});

  if ($is_associated) {
    return (undef, 'User is already part of an existing plan.');
  }

  my $existing_plan = $user_pricing_plan_rs->find({user_id => $self->user_id});

  if ($existing_plan) {
    $existing_plan->delete();
  }

  my $user_pricing_plan = $user_pricing_plan_rs->create(
    {user_id => $self->user_id, pricing_plan_id => $self->pricing_plan_id});

  $guard->commit;

  return ($user_pricing_plan, undef);
}

1;
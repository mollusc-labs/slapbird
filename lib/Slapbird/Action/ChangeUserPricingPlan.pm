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


package Slapbird::Action::ChangeUserPricingPlan;

use Moo;
use Types::Standard qw(Str Object);
use Try::Tiny;

has schema               => (is => 'ro', isa => Object, required => 1);
has user_pricing_plan_id => (is => 'ro', isa => Str,    required => 1);
has pricing_plan_id      => (is => 'ro', isa => Str,    required => 1);

sub execute {
  my ($self) = @_;

  my $user_pricing_plan = $self->schema->resultset('UserPricingPlan')
    ->find({user_pricing_plan_id => $self->user_pricing_plan_id});

  my $pricing_plan = $self->schema->resultset('PricingPlan')
    ->find({pricing_plan_id => $self->pricing_plan_id});

  if (!$pricing_plan) {
    return (undef,
      'Pricing plan: ' . $self->pricing_plan_id . ' does not exist.');
  }

  $user_pricing_plan->{pricing_plan_id} = $pricing_plan->pricing_plan_id;

  try {
    return ($user_pricing_plan->save(), undef);
  }
  catch {
    return (undef, $_);
  };
}

1;

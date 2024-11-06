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


package Slapbird::Action::DeleteAssociatedUserPricingPlan;

use Moo;
use Types::Standard qw(Str Object);
use Try::Tiny;

has schema => (isa => Object, is => 'ro', required => 1);
has associated_user_pricing_plan_id => (isa => Str, is => 'ro', required => 1);

sub execute {
  my ($self) = @_;

  try {
    my $associated_user_pricing_plan
      = $self->schema->resultset('AssociatedUserPricingPlan')->find({
      associated_user_pricing_plan_id => $self->associated_user_pricing_plan_id
      });

    my @applications = $self->schema->resultset('UserPricingPlan')->find({
      user_pricing_plan_id =>
        $associated_user_pricing_plan->user_pricing_plan_id
    })->applications;

    for (@applications) {
      $_->{user_id} = $associated_user_pricing_plan->user_pricing_plan->user_id;
      $_->update();
    }

    $associated_user_pricing_plan->delete();

    return (1, undef);
  }
  catch {
    return (undef, $_);
  }
}

1;

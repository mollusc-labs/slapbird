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


package Slapbird::Action::CreateStripeCustomerForUser;

use Moo;
use Types::Standard qw(Object Str);
use Try::Tiny;

has schema  => (is => 'ro', isa => Object, required => 1);
has stripe  => (is => 'ro', isa => Object, required => 1);
has user_id => (is => 'ro', isa => Str,    required => 1);

sub execute {
  my ($self) = @_;

  my $user
    = $self->schema->resultset('User')->find({user_id => $self->user_id});

  if (!$user) {
    return (undef, 'No user associated with user_id');
  }

  try {
    my $customer = $self->stripe->customers(
      create => {
        name     => $user->name,
        email    => $user->email,
        metadata => {user_id => $user->user_id}
      }
    );

    $user->update({stripe_id => $customer->id});

    return ($customer->id, undef);
  }
  catch {
    return (undef, $_);
  }
}

1;

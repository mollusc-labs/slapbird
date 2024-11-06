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


package Slapbird::Action::CreateApplication;

use Moo;
use Types::Standard qw(Str);
use Slapbird::Util  qw(slugify);

has schema                  => (is => 'ro', required => 1);
has application_name        => (is => 'ro', isa      => Str, required => 1);
has user_id                 => (is => 'ro', isa      => Str, required => 1);
has application_description => (is => 'ro', isa      => Str);
has user_pricing_plan_id    => (is => 'ro', isa      => Str, required => 1);

sub execute {
  my ($self) = @_;

  return try {
    return (
      $self->schema->resultset('Application')->create({
        name                 => $self->application_name,
        slug                 => slugify($self->application_name),
        user_pricing_plan_id => $self->user_pricing_plan_id,
        description          => $self->application_description,
        user_id              => $self->user_id
      }),
      undef
    );
  }
  catch {
    return (undef, $_);
  };
}

1;

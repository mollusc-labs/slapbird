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


package Slapbird::Action::CreateApiKey;

use Moo;
use Types::Standard qw(Str Bool);
use Data::ULID      qw(ulid);

has schema           => (is => 'ro', required => 1);
has api_key_name     => (is => 'ro', isa      => Str,  required => 1);
has application_id   => (is => 'ro', isa      => Str,  required => 1);
has application_slug => (is => 'ro', isa      => Str,  required => 1);
has user_id          => (is => 'ro', isa      => Str,  required => 1);
has active           => (is => 'ro', isa      => Bool, default  => sub {1});

sub execute {
  my ($self) = @_;

  return try {
    return (
      $self->schema->resultset('ApiKey')->create({
        name                => $self->api_key_name,
        active              => $self->active,
        user_id             => $self->user_id,
        application_id      => $self->application_id,
        application_api_key => (ulid() . $self->application_slug),
      }),
      undef
    );
  }
  catch {
    return (undef, $_);
  };
}

1;
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


package Slapbird::Action::AddHttpTransaction;

use Moo;
use Types::Standard qw(HashRef);
use Slapbird::Sanitizer::HTTPTransaction;

has schema => (is => 'ro', required => 1);
has http_transaction => (is => 'ro', required => 1, isa => HashRef);

sub execute {
  my ($self) = @_;

  my $sanitized_transaction
    = Slapbird::Sanitizer::HTTPTransaction->sanitize($self->http_transaction);

  return $self->schema->resultset('HTTPTransaction')
    ->create($sanitized_transaction);
}

1;
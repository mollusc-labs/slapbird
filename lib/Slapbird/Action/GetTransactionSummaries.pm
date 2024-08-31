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


package Slapbird::Action::GetTransactionSummaries;

use Moo;
use Types::Standard qw(Str Int LaxNum Object Maybe);

has schema         => (is => 'ro', isa => Object, required => 1);
has page           => (is => 'ro', isa => Int,    default  => sub {1});
has size           => (is => 'ro', isa => Int,    default  => sub {15});
has end_point      => (is => 'ro', isa => Str,    required => 1);
has code           => (is => 'ro', isa => Maybe [Int]);
has from           => (is => 'ro', isa => LaxNum);
has to             => (is => 'ro', isa => LaxNum);
has application_id => (is => 'ro', isa => Str, required => 1);

sub execute {
  my ($self) = @_;

  my $rs = $self->schema->resultset('HTTPTransaction')->search(
    {
      application_id => $self->application_id,
      start_time     => {-between => [$self->from, $self->to]},
      $self->end_point ? (end_point     => $self->end_point) : (),
      $self->code      ? (response_code => $self->code)      : ()
    },
    {
      page     => $self->page,
      rows     => $self->size,
      order_by => {-desc => 'start_time'}
    }
  );

  return ($rs->pager, [$rs->all]);
}

1;
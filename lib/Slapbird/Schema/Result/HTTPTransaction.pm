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


package Slapbird::Schema::Result::HTTPTransaction;

use base 'DBIx::Class::Core';
use strict;
use warnings;

__PACKAGE__->table('http_transactions');
__PACKAGE__->load_components(qw(InflateColumn::DateTime TimeStamp));

__PACKAGE__->add_columns(qw(
  application_id
  type
  method
  end_point
  start_time
  end_time
  total_time
  response_code
  response_size
  response_headers
  request_id
  request_size
  request_headers
  handler
  error
  requestor
  stack
  os
));

__PACKAGE__->add_columns(
  created_at => {data_type => 'datetime', set_on_create => 1});

__PACKAGE__->add_columns(http_transaction_id => {is_auto_increment => 1});

__PACKAGE__->set_primary_key('http_transaction_id');

sub to_graph_dto {
  my $self = shift;
  return +{
    application_id => $self->application_id,
    type           => $self->type,
    response_code  => $self->response_code,
    handler        => $self->handler,
    was_error      => defined $self->error,
    total_time     => $self->total_time + 0,
    start_time     => $self->start_time + 0,
    end_time       => $self->end_time + 0
  };
}

1;

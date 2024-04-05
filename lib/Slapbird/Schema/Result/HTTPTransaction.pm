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
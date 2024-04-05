package Slapbird::Action::DeleteApiKey;

use Moo;
use Types::Standard qw(Str Object);

has schema     => (is => 'ro', isa => Object);
has api_key_id => (is => 'ro', isa => Str);

sub execute {
  my ($self) = @_;

  return $self->schema->resultset('ApiKey')
    ->find({api_key_id => $self->api_key_id})->delete();
}

1;

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
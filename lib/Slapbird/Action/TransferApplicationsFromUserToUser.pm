package Slapbird::Action::TransferApplicationsFromUserToUser;

use Moo;
use Types::Standard qw(Str Object);
use Try::Tiny;

has schema       => (is => 'ro', isa => Object, required => 1);
has to_user_id   => (is => 'ro', isa => Str,    required => 1);
has from_user_id => (is => 'ro', isa => Str,    required => 1);

sub execute {
  my ($self) = @_;

  if ($self->to_user_id eq $self->from_user_id) {
    return (1, undef);
  }

  try {
    $self->schema->resultset('Application')
      ->search({user_id => $self->to_user_id})
      ->update({user_id => $self->from_user_id});

    return (1, undef);
  }
  catch {
    return (undef, $_);
  };
}

1;

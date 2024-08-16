package Slapbird::Action::DeleteApplication;

use Moo;
use Types::Standard qw(Str Object);
use Try::Tiny;

has schema         => (is => 'ro', isa => Object);
has application_id => (is => 'ro', isa => Str);

sub execute {
  my ($self) = @_;

  try {
    $self->schema->resultset('HTTPTransaction')
      ->search({application_id => $self->application_id})->delete();
  }
  catch {
    return (undef, $_);
  };

  try {
    return (
      $self->schema->resultset('Application')
        ->find({application_id => $self->application_id})->delete(),
      undef
    );
  }
  catch {
    return (undef, $_);
  }
}

1;

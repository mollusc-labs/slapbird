package Slapbird::Action::DeleteApplication;

use Moo;
use Types::Standard qw(Str Object);

has schema         => (is => 'ro', isa => Object);
has application_id => (is => 'ro', isa => Str);

sub execute {
  my ($self) = @_;

  return $self->schema->resultset('Application')
    ->find({application_id => $self->application_id})->delete();
}

1;

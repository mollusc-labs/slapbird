package Slapbird::Advice::ErrorAdvice;

use Moo;
use Types::Standard qw(ArrayRef);
use Time::Piece;
use namespace::clean;

has errors => (is => 'ro', required => 1, isa => ArrayRef);
has time => (is => 'ro', default => sub { return localtime->epoch(); });

sub to_hashref {
  my ($self) = @_;
  return +{'time' => $self->time, errors => $self->errors};
}

1;

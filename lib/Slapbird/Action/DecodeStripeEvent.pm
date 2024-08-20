package Slapbird::Action::DecodeStripeEvent;

use Moo;
use Types::Standard qw(Str);
use Encode;

has payload => (is => 'ro', isa => Str, required => 1);
has header  => (is => 'ro', isa => Str, required => 1);
has _schema => (is => 'ro', isa => Str, default  => sub {'v1'});

sub execute {
  my ($self) = @_;

  my $decoded_payload = Encode::decode('utf8', $self->payload);
  my $decoded_header  = Encode::decode('utf8', $self->payload);

  my @signatures;
  my $timestamp = -1;

  for (split(',', $decoded_header)) {
    my ($key, $value) = split('=', $_);

    if ($key eq 't') {
      $timestamp = 0 + $value;
    }

    if ($key eq $self->_schema) {
      push @signatures, $value;
    }
  }

  if ($timestamp == -1) {
    return (undef, 'Unable to extract timestamp and signature from header');
  }

  if (!@signatures) {
    return (undef, 'No signatures found with schema');
  }
}

1;

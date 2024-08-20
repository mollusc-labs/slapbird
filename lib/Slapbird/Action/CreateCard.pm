package Slapbird::Action::CreateCard;

use Moo;
use Types::Standard qw(Object Str);
use Try::Tiny;

has schema   => (isa => Object, is => 'ro', required => 1);
has stripe   => (isa => Object, is => 'ro', required => 1);
has customer => (isa => Object, is => 'ro', required => 1);
has number   => (isa => Str,    is => 'ro', required => 1);
has mm       => (isa => Str,    is => 'ro', required => 1);
has yy       => (isa => Str,    is => 'ro', required => 1);
has cvc      => (isa => Str,    is => 'ro', required => 1);

sub execute {
  my ($self) = @_;

  my $stripe_card;
  try {
    $stripe_card = $self->stripe->cards(
      create => {
        customer => $self->customer,
        card     => {
          number    => $self->number,
          exp_month => $self->mm,
          exp_year  => $self->yy,
          cvc       => $self->cvc
        }
      }
    );
  }
  catch {
    return (undef, $_);
  };

  use DDP;
  p $stripe_card;

  return ($stripe_card, undef);
}

1;

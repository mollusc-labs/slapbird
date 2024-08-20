package Slapbird::Action::CreateStripeCustomerForUser;

use Moo;
use Types::Standard qw(Object Str);
use Try::Tiny;

has schema  => (is => 'ro', isa => Object, required => 1);
has stripe  => (is => 'ro', isa => Object, required => 1);
has user_id => (is => 'ro', isa => Str,    required => 1);

sub execute {
  my ($self) = @_;

  my $user
    = $self->schema->resultset('User')->find({user_id => $self->user_id});

  if (!$user) {
    return (undef, 'No user associated with user_id');
  }

  try {
    my $customer = $self->stripe->customers(
      create => {
        name     => $user->name,
        email    => $user->email,
        metadata => {user_id => $user->user_id}
      }
    );

    $user->update({stripe_id => $customer->id});

    return (1, undef);
  }
  catch {
    return (undef, $_);
  }
}

1;

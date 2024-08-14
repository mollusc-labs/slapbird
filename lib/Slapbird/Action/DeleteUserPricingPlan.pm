package Slapbird::Action::DeleteUserPricingPlan;

use Moo;
use Types::Standard qw(Str Object);
use Try::Tiny;

has schema               => (isa => Object, is => 'ro', required => 1);
has user_pricing_plan_id => (isa => Str,    is => 'ro', required => 1);

sub execute {
  my ($self) = @_;

  try {
    $self->schema->resultset('UserPricingPlan')
      ->find({user_pricing_plan_id => $self->user_pricing_plan_id})->delete();
    return (1, undef);
  }
  catch {
    return (undef, $_);
  }

}

1;

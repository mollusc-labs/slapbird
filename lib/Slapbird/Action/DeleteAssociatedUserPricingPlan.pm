package Slapbird::Action::DeleteAssociatedUserPricingPlan;

use Moo;
use Types::Standard qw(Str Object);
use Try::Tiny;

has schema => (isa => Object, is => 'ro', required => 1);
has associated_user_pricing_plan_id => (isa => Str, is => 'ro', required => 1);

sub execute {
  my ($self) = @_;

  try {
    $self->schema->resultset('AssociatedUserPricingPlan')
      ->find(
      {associated_user_pricing_plan_id => $self->associated_user_pricing_id})
      ->delete();
    return (1, undef);
  }
  catch {
    return (undef, $_);
  }
}

1;

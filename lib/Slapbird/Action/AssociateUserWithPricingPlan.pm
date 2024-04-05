package Slapbird::Action::AssociateUserWithPricingPlan;

use Moo;
use Types::Standard qw(Str);

has schema               => (is => 'ro', required => 1);
has user_id              => (is => 'ro', isa      => Str, required => 1);
has user_pricing_plan_id => (is => 'ro', isa      => Str, required => 1);

sub execute {
  my ($self) = @_;

  my $guard = $self->schema->txn_scope_guard;

  my $user_pricing_plan_rs = $self->schema->resultset('UserPricingPlan');
  my $associated_pricing_plan_rs
    = $self->schema->resultset('AssociatedUserPricingPlan');

  my $existing_plan = $user_pricing_plan_rs->find({user_id => $self->user_id});

  if ($existing_plan) {
    return (undef, 'User is an owner of an existing plan.');
  }

  my $potential_association
    = $associated_pricing_plan_rs->find({user_id => $self->user_id});

  if ($potential_association) {
    $potential_association->delete();
  }

  my $associated_pricing_plan = $associated_pricing_plan_rs->create({
    user_id              => $self->user_id,
    user_pricing_plan_id => $self->user_pricing_plan_id
  });

  $guard->commit;

  return ($associated_pricing_plan, undef);
}

1;
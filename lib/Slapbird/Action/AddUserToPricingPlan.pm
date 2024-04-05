package Slapbird::Action::AddUserToPricingPlan;

use Moo;
use Types::Standard qw(Str);

has schema          => (is => 'ro', required => 1);
has user_id         => (is => 'ro', isa      => Str, required => 1);
has pricing_plan_id => (is => 'ro', isa      => Str, required => 1);

sub execute {
  my ($self) = @_;

  my $guard = $self->schema->txn_scope_guard;

  my $user_pricing_plan_rs = $self->schema->resultset('UserPricingPlan');
  my $associated_pricing_plan_rs
    = $self->schema->resultset('AssociatedUserPricingPlan');

  my $is_associated
    = $associated_pricing_plan_rs->find({user_id => $self->user_id});

  if ($is_associated) {
    return (undef, 'User is already part of an existing plan.');
  }

  my $existing_plan = $user_pricing_plan_rs->find({user_id => $self->user_id});

  if ($existing_plan) {
    $existing_plan->delete();
  }

  my $user_pricing_plan = $user_pricing_plan_rs->create(
    {user_id => $self->user_id, pricing_plan_id => $self->pricing_plan_id});

  $guard->commit;

  return ($user_pricing_plan, undef);
}

1;
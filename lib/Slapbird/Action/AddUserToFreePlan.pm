package Slapbird::Action::AddUserToFreePlan;

use Moo;
use Try::Tiny;

has schema  => (is => 'ro', required => 1);
has user_id => (is => 'ro', required => 1);

sub execute {
  my ($self) = @_;

  my $free_plan_id
    = $self->schema->resultset('PricingPlan')->find({price => 0, active => 1})
    ->pricing_plan_id;

  my ($user_pricing_plan, $error)
    = Slapbird::Action::AddUserToPricingPlan->new(
    user_id         => $self->user_id,
    pricing_plan_id => $free_plan_id,
    schema          => $self->schema
  )->execute();

  return ($user_pricing_plan, $error);
}

1;
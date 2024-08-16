package Slapbird::Action::ChangeUserPricingPlan;

use Moo;
use Types::Standard qw(Str Object);
use Try::Tiny;

has schema               => (is => 'ro', isa => Object, required => 1);
has user_pricing_plan_id => (is => 'ro', isa => Str,    required => 1);
has pricing_plan_id      => (is => 'ro', isa => Str,    required => 1);

sub execute {
  my ($self) = @_;

  my $user_pricing_plan = $self->schema->resultset('UserPricingPlan')
    ->find({user_pricing_plan_id => $self->user_pricing_plan_id});

  my $pricing_plan = $self->schema->resultset('PricingPlan')
    ->find({pricing_plan_id => $self->pricing_plan_id});

  if (!$pricing_plan) {
    return (undef,
      'Pricing plan: ' . $self->pricing_plan_id . ' does not exist.');
  }

  $user_pricing_plan->{pricing_plan_id} = $pricing_plan->pricing_plan_id;

  try {
    return ($user_pricing_plan->save(), undef);
  }
  catch {
    return (undef, $_);
  };
}

1;

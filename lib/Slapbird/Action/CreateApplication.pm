package Slapbird::Action::CreateApplication;

use Moo;
use Types::Standard qw(Str);
use Slapbird::Util  qw(slugify);

has schema                  => (is => 'ro', required => 1);
has application_name        => (is => 'ro', isa      => Str, required => 1);
has user_id                 => (is => 'ro', isa      => Str, required => 1);
has application_description => (is => 'ro', isa      => Str);
has user_pricing_plan_id    => (is => 'ro', isa      => Str, required => 1);

sub execute {
  my ($self) = @_;

  return try {
    return (
      $self->schema->resultset('Application')->create({
        name                 => $self->application_name,
        slug                 => slugify($self->application_name),
        user_pricing_plan_id => $self->user_pricing_plan_id,
        description          => $self->application_description,
        user_id              => $self->user_id
      }),
      undef
    );
  }
  catch {
    return (undef, $_);
  };
}

1;

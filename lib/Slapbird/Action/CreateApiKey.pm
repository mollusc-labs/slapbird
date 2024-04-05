package Slapbird::Action::CreateApiKey;

use Moo;
use Types::Standard qw(Str Bool);
use Data::ULID      qw(ulid);

has schema           => (is => 'ro', required => 1);
has api_key_name     => (is => 'ro', isa      => Str,  required => 1);
has application_id   => (is => 'ro', isa      => Str,  required => 1);
has application_slug => (is => 'ro', isa      => Str,  required => 1);
has user_id          => (is => 'ro', isa      => Str,  required => 1);
has active           => (is => 'ro', isa      => Bool, default  => sub {1});

sub execute {
  my ($self) = @_;

  return try {
    return (
      $self->schema->resultset('ApiKey')->create({
        name                => $self->api_key_name,
        active              => $self->active,
        user_id             => $self->user_id,
        application_id      => $self->application_id,
        application_api_key => (ulid() . $self->application_slug),
      }),
      undef
    );
  }
  catch {
    return (undef, $_);
  };
}

1;
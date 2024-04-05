package Slapbird::Action::CreateApplication;

use Moo;
use Types::Standard qw(Str);
use Unicode::Normalize;

has schema                  => (is => 'ro', required => 1);
has application_name        => (is => 'ro', isa      => Str, required => 1);
has user_id                 => (is => 'ro', isa      => Str, required => 1);
has application_description => (is => 'ro', isa      => Str);
has user_pricing_plan_id    => (is => 'ro', isa      => Str, required => 1);

sub _slugify($) {
  my ($self, $input) = @_;

  $input = NFKD($input);         # Normalize (decompose) the Unicode string
  $input =~ tr/\000-\177//cd;    # Strip non-ASCII characters (>127)
  $input =~ s/[^\w\s-]//g
    ; # Remove all characters that are not word characters (includes _), spaces, or hyphens
  $input =~ s/^\s+|\s+$//g;    # Trim whitespace from both ends
  $input = lc($input);
  $input =~ s/[-\s]+/-/g
    ;    # Replace all occurrences of spaces and hyphens with a single hyphen

  return $input;
}

sub execute {
  my ($self) = @_;

  return try {
    return (
      $self->schema->resultset('Application')->create({
        name                 => $self->application_name,
        slug                 => $self->_slugify($self->application_name),
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

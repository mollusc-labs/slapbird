package Slapbird::Sanitizer::Application;

use strict;
use warnings;

sub _validator {
  my $jv = JSON::Validator->new();

  $jv->schema({
    type       => 'object',
    required   => ['name', 'type'],
    properties => {
      name        => {type => 'string', maxLength => 100},
      description => {type => 'string', maxLength => 400},
      type => {type => 'string', enum => ['mojo', 'plack', 'dancer', 'other']}
    }
  });

  return $jv;
}

sub sanitize {
  my ($class, $json) = @_;

  my @basic_errors = $class->_validator->validate($json);

  return undef, \@basic_errors if @basic_errors;

  return $json, undef;
}

1;
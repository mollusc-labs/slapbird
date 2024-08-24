package Slapbird::Validator::Application;

use strict;
use warnings;
use feature 'state';
use JSON::Validator;
use Slapbird::Enum::ApplicationTypes;

sub _validator {
  state $jv;

  return $jv if ($jv);

  $jv = JSON::Validator->new();

  $jv->schema({
    type       => 'object',
    required   => ['name', 'type'],
    properties => {
      name        => {type => 'string', maxLength => 100},
      description => {type => 'string', maxLength => 400},
      type        =>
        {type => 'string', enum => [Slapbird::Enum::ApplicationTypes->all]}
    }
  });

  return $jv;
}

sub validate {
  my ($class, $json) = @_;

  my @basic_errors = $class->_validator->validate($json);

  return undef, \@basic_errors if @basic_errors;

  return $json, undef;
}

1;

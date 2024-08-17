package Slapbird::Validator::HTTPTransaction;

use Moo;
use feature 'state';

sub validate {
  my ($class, $object) = @_;

  my $jv = JSON::Validator->new();

  $jv->schema({
    type     => 'object',
    required => [
      'type',      'method',        'end_point',    'start_time',
      'end_time',  'response_code', 'request_size', 'error',
      'requestor', 'handler'
    ],
    properties => {
      type             => {type => 'string', enum => ['mojo', 'plack']},
      method           => {type => 'string'},
      end_point        => {type => 'string'},
      start_time       => {type => 'number'},
      end_time         => {type => 'number'},
      response_code    => {type => 'integer'},
      response_size    => {type => ['integer', 'null']},
      request_size     => {type => ['integer', 'null']},
      handler          => {type => ['string',  'null']},
      error            => {type => ['string',  'null']},
      requestor        => {type => ['string',  'null']},
      request_headers  => {type => 'object'},
      response_headers => {type => 'object'},
      stack            => {
        type  => 'array',
        items => {
          additionalProperties => 0,
          properties           => {
            start_time => {type => 'number'},
            end_time   => {type => 'number'},
            name       => {type => 'string'}
          },
          required => ['start_time', 'end_time', 'name']
        }
      },
      os => {type => ['string', 'null']}
    }
  });

  my @errors = $jv->validate($object);

  return @errors if @errors;

  # TODO: (RF) as more things like Dancer2, Plack are added to the agent
  # This will need to dispatch on the type.
  return $class->_validate_mojo($object) if $object->{type} eq 'mojo';

  return ();
}

sub _validator_mojo {
  my ($class) = @_;

  state $jv;

  return $jv if $jv;

  $jv = JSON::Validator->new();

  $jv->schema({
    type       => 'object',
    required   => ['request_id'],
    properties => {request_id => {type => 'string'},}
  });

  return $jv;
}

sub _validate_mojo {
  my ($class, $object) = @_;
  return $class->_validator_mojo->validate($object);
}

1;

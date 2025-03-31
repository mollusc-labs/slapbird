use strict;
use warnings;

use lib 'lib';

use Test::More;
use Time::HiRes qw(time);
use Slapbird::Validator::HTTPTransaction;
use Slapbird::Validator::Application;
use Try::Tiny;

my @stack = (
  {start_time => 100_000, end_time => 100_100, name => 'foo::bar'},
  {start_time => 99_999,  end_time => 109_999, name => 'dbi::do_stuff'}
);

my @queries = (
  {sql => 'select * from users', total_time => 1},
  {sql => 'select * from users', total_time => 2}
);

my $http_transaction = {
  request_id       => '1111',
  stack            => \@stack,
  handler          => undef,
  method           => 'GET',
  requestor        => 'other_app',
  request_size     => 1,
  response_code    => 400,
  start_time       => 1725630339761,
  end_time         => 1725631339761,
  end_point        => '/foo',
  error            => "error\nother_error\nanother_error",
  request_headers  => {foo => 'bar'},
  response_headers => {bar => 'baz'},
  queries          => \@queries,
  type             => 'mojo'
};

my (@errors)
  = Slapbird::Validator::HTTPTransaction->validate($http_transaction);

is scalar @errors, 0, 'no errors on valid http transaction?';

$http_transaction->{type} = 'dancer2';
(@errors) = Slapbird::Validator::HTTPTransaction->validate($http_transaction);
is scalar @errors, 0, 'is no errors for dancer2 type?';

$http_transaction->{type} = 'plack';
(@errors) = Slapbird::Validator::HTTPTransaction->validate($http_transaction);
is scalar @errors, 0, 'is no errors for plack type?';

$http_transaction->{type} = 'bad';
(@errors) = Slapbird::Validator::HTTPTransaction->validate($http_transaction);
is scalar @errors, 1, 'is single error for bad type?';
ok index($errors[0], "/type: Not in enum list:") == 0,
  'is correct error for bad type?';

$http_transaction->{type} = 'mojo';

# Delete required "request_id" that is required by 'mojo' type transactions
delete $http_transaction->{request_id};

(@errors) = Slapbird::Validator::HTTPTransaction->validate($http_transaction);

is scalar @errors, 1, 'is just request_id missing?';
is $errors[0], '/request_id: Missing property.',
  'is correct error for request_id missing?';

delete $http_transaction->{type};
(@errors) = Slapbird::Validator::HTTPTransaction->validate($http_transaction);

is scalar @errors, 1,                      'is correct number of errors?';
is $errors[0], '/type: Missing property.', 'is correct error for type missing?';

$http_transaction->{type} = 'mojo';

done_testing;

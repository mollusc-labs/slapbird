use strict;
use warnings;

use lib 'lib';

use Test::Slapbird::App;
use Test::More;

BEGIN {
  use_ok 'Slapbird';
}

test_app()->get_ok('/')->status_is(200);
test_app()->get_ok('/pricing')->status_is(200);

done_testing;

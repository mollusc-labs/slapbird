use strict;
use warnings;

use Test::More;

BEGIN {
      use Dancer2;
      use_ok 'Dancer2::Plugin::SlapbirdAPM';
}

done_testing;

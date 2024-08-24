package Slapbird::Enum::ApplicationTypes;

use strict;
use warnings;
use Const::Fast;

const my @VALUES => qw(mojo dancer2 plack);

sub all {
  return wantarray ? @VALUES : [@VALUES];
}

1;

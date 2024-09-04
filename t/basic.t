use strict;
use warnings;

use lib 'lib';

use Test::Slapbird::DB;
use Test::More;
use Test::Mojo;

BEGIN {
  use_ok 'Slapbird';
}

my $t = Test::Mojo->new('Slapbird');

$t->get_ok('/')->status_is(200);
$t->get_ok('/pricing')->status_is(200);

done_testing;

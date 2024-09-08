package Test::Slapbird::App;

use strict;
use warnings;
use feature qw(state);
use Exporter 'import';
use Test::Mojo;
use Test::Slapbird::DB;

our @EXPORT = qw(test_app);

sub test_app {
  return state $test = Test::Mojo->new('Slapbird');
}

1;

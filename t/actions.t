use strict;
use warnings;

use lib 'lib';

use Test::More;
use Time::HiRes qw(time);
use Try::Tiny;
use Mojo::File;
use Slapbird::Actions;
use String::CamelCase qw(decamelize);

my $klass = Slapbird::Actions->helper->();

for (map {s/\.pm//grxm}
  map { $_->basename } @{Mojo::File->new('lib/Slapbird/Action')->list})
{
  ## no critic [TestingAndDebugging::ProhibitNoStrict]
  no strict 'refs';
  my $pkg = 'Slapbird::Action::' . $_;
  ok $pkg->can('execute'), 'action ' . $_ . ' can execute?';
  ok $klass->can(decamelize($_)),
    'action ' . decamelize($_) . ' is available on Slapbird::Actions?';
}

done_testing;

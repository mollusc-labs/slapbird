#!/usr/bin/env perl

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME     => 'SlapbirdAPM::Agent::Dancer2',
  ABSTRACT =>
    'Agent software for the Perl application performance monitor, Slapbird. slapbirdapm.com',
  VERSION_FROM => 'lib/SlapbirdAPM/Agent/Dancer2.pm',
  AUTHOR       => 'Rawley Fowler, Mollusc Labs',
  LICENSE      => 'mit',
  META_MERGE   => {
    dynamic_config => 0,
    'meta-spec'    => {version   => 2},
    no_index       => {directory => ['examples', 't']},
    prereqs        => {runtime   => {requires => {perl => '5.024'}}},
    resources      => {
      bugtracker => {web => 'https://github.com/mollusc-labs/slapbird/issues'},
      license    => [qq{http://www.opensource.org/licenses/mit}],
      repository =>
        {type => 'git', url => 'https://github.com/mollusc-labs/slapbird'}
    },
  },
  PREREQ_PM => {
    'Carp'                 => '0',
    'Dancer2'              => '0',
    'Const::Fast'          => '0.014',
    'Try::Tiny'            => '0.31',
    'ExtUtils::MakeMaker'  => '7.12',
    'Type::Tiny'           => '0',
    'LWP::UserAgent'       => '6.77',
    'LWP::Protocol::https' => '6.14',
    'System::Info'         => '0',
    'JSON::MaybeXS'        => '1.004008',
    'Time::HiRes'          => '0'
  },
  test => {TESTS => 't/*.t t/*/*.t'}
);

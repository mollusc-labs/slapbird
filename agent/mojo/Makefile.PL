#!/usr/bin/env perl

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME     => 'SlapbirdAPM::Agent::Mojo',
  ABSTRACT =>
    'Agent software for the Perl application performance monitor, Slapbird. slapbirdapm.com',
  VERSION_FROM => 'lib/SlapbirdAPM/Agent/Mojo.pm',
  PREREQ_PM    => {'ExtUtils::MakeMaker' => '7.12'},
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
    'Carp'             => '0',
    'Try::Tiny'        => '0.31',
    'Const::Fast'      => '0.014',
    'Mojolicious'      => '0',
    'IPC::Open2'       => '0',
    'namespace::clean' => '0.27',
    'Time::Piece'      => '1.3401',
    'Time::HiRes'      => '1.9764',
    'System::Info'     => '0.064'
  },
  test => {TESTS => 't/*.t t/*/*.t'}
);

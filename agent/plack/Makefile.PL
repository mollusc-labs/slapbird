#!/usr/bin/env perl

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME     => 'SlapbirdAPM::Agent::Plack',
  ABSTRACT =>
    'A Plack agent software for the Perl application performance monitor, Slapbird. slapbirdapm.com',
  VERSION_FROM => 'lib/SlapbirdAPM/Agent/Plack.pm',
  PREREQ_PM    => {'ExtUtils::MakeMaker' => '7.12'},
  AUTHOR       => 'Rawley Fowler, Mollusc Labs',
  LICENSE      => 'mit',
  META_MERGE   => {
    dynamic_config => 0,
    'meta-spec'    => {version   => 2},
    no_index       => {directory => ['examples', 't']},
    prereqs        => {runtime   => {requires => {perl => '5.024'}}},
    resources      => {
      bugtracker => {web => 'https://github.com/mollusc-labs/Slapbird/issues'},
      license    => [qq{http://www.opensource.org/licenses/mit}],
      repository =>
        {type => 'git', url => 'https://github.com/mollusc-labs/Slapbird'}
    },
  },
  PREREQ_PM => {
    'Carp'           => '0',
    'Try::Tiny'      => '0',
    'Plack'          => '0',
    'JSON::MaybeXS'  => '0',
    'AnyEvent'       => '0',
    'AnyEvent::HTTP' => '0'
  },
  test => {TESTS => 't/*.t t/*/*.t'}
);

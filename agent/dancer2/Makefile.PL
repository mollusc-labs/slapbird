#!/usr/bin/env perl

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'SlapbirdAPM::Agent',
  ABSTRACT     => 'Agent software for the Perl application performance monitor, Slapbird. slapbirdapm.com',
  VERSION_FROM => 'lib/SlapbirdAPM/Agent.pm',
  PREREQ_PM    => {'ExtUtils::MakeMaker' => '7.12'},
  AUTHOR       => 'Rawley Fowler, Mollusc Labs',
  LICENSE      => 'mit',
  META_MERGE   => {
    dynamic_config => 0,
    'meta-spec'    => {version   => 2},
    no_index       => {directory => ['examples', 't']},
    prereqs        => {runtime   => {requires => {perl => '5.016'}}},
    resources      => {
      bugtracker => {web => 'https://github.com/mollusc-labs/Slapbird/issues'},
      license    => [qq{http://www.opensource.org/licenses/mit}],
      repository => {type => 'git', url => 'https://github.com/mollusc-labs/Slapbird'}
    },
  },
  PREREQ_PM => {
    'Carp'             => '*',
    'Try::Tiny'        => '*',
    'Plack'            => '*',
    'Const::Fast'      => '*',
    'Mojolicious'      => '*',
    'AnyEvent'         => '*',
    'JSON::MaybeXS'    => '*',
    'namespace::clean' => '*',
    'Time::Piece'      => '*',
    'IO::Handle'       => '0'
  },
  test => {TESTS => 't/*.t t/*/*.t'}
);
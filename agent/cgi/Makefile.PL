#!/usr/bin/env perl

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME     => 'SlapbirdAPM::Agent::CGI',
  ABSTRACT =>
    'A CGI agent software for the Perl application performance monitor, Slapbird. slapbirdapm.com',
  VERSION_FROM => 'lib/SlapbirdAPM/Agent/CGI.pm',
  PREREQ_PM    => {'ExtUtils::MakeMaker' => '7.12'},
  AUTHOR       => 'Rawley Fowler, Mollusc Software Solutions',
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
    'CGI'            => '0',
    'JSON'           => '0',
    'LWP::UserAgent' => '0',
    'System::Info'   => '0.064',
    'DBI'            => '0',
    'IO::Pipe'       => '0',
    'IO::Tee'        => '0',
    'Time::HiRes'    => '0',
    'POSIX'          => '0'
  },
  test => {TESTS => 't/*.t t/*/*.t'}
);

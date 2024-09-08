# This file is apart of SlapbirdAPM, a Free and Open-Source
# web application APM for Perl 5 web applications.
#
# Copyright (C) 2024  Mollusc Labs Inc.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


package Slapbird::Sanitizer::Stack;

use strict;
use warnings;
use HTML::Escape qw(escape_html);
use namespace::clean;

sub sanitize {
  my ($class, $stack, $total_time) = @_;

  return undef unless ref($stack) eq 'ARRAY';

  for (@$stack) {
    $_->{total_time} = sprintf('%.2f', $_->{end_time} - $_->{start_time});
  }

  my @stack_peices = map {
        '<div class="slapbird-stack-row">'
      . '<span class="slapbird-stack-row-name">'
      . escape_html($_->{name})
      . '</span> - <span class="slapbird-stack-row-time">'
      . escape_html(sprintf('%.2f', $_->{end_time} - $_->{start_time}))
      . '</span>ms'
      . '</div>'
  } sort { $a->{total_time} <=> $b->{total_time} } @$stack;

  return join "\n", @stack_peices;
}

1;

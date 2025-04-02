# This file is apart of SlapbirdAPM, a Free and Open-Source
# web application APM for Perl 5 web applications.
#
# Copyright (C) 2024  Mollusc Labs.
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


package Slapbird::Sanitizer::Query;

use strict;
use warnings;

use SQL::Beautify;
use Const::Fast;

const my $sb => SQL::Beautify->new();

sub sanitize {
  my ($class, $query_orig) = @_;

  return undef unless ref($query_orig) eq 'HASH';

  my $query = {%$query_orig};

  $sb->query($query->{sql});
  $query->{sql} = $sb->beautify;

  return $query;
}

1;

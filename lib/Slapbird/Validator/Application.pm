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


package Slapbird::Validator::Application;

use strict;
use warnings;
use feature 'state';
use JSON::Validator;
use Slapbird::Enum::ApplicationTypes;

sub _validator {
  state $jv;

  return $jv if ($jv);

  $jv = JSON::Validator->new();

  $jv->schema({
    type       => 'object',
    required   => ['name', 'type'],
    properties => {
      name        => {type => 'string', maxLength => 100},
      description => {type => 'string', maxLength => 400},
      type        =>
        {type => 'string', enum => [Slapbird::Enum::ApplicationTypes->all]}
    }
  });

  return $jv;
}

sub validate {
  my ($class, $json) = @_;

  my @basic_errors = $class->_validator->validate($json);

  return undef, \@basic_errors if @basic_errors;

  return $json, undef;
}

1;

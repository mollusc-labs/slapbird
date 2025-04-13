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


package Slapbird::Validator::HealthCheckConfig;

use strict;
use warnings;
use feature 'state';
use JSON::Validator;
use Const::Fast;
use Mojo::UserAgent;
use Slapbird::Addon::HealthCheck;

const my $ua => Mojo::UserAgent->new();

sub _validator {
  state $jv;

  return $jv if ($jv);

  $jv = JSON::Validator->new();

  $jv->schema({
    type       => 'object',
    required   => [Slapbird::Addon::HealthCheck->param_keys()],
    properties => {endpoint => {type => 'string'},}
  });

  return $jv;
}

sub validate {
  my ($class, $json) = @_;

  my $jv = $class->_validator();

  my @basic_errors = $class->_validator->validate($json);

  return undef, \@basic_errors if @basic_errors;

  if ($json->{endpoint}
    !~ /https?:\/\/(www\.)?[-a-zA-Z0-9\@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()\@:%_\+.~#?&\/\/=]*)/xmi
    )
  {
    return undef, ['Not a valid email address.'];
  }

  my $res = $ua->get($json->{endpoint})->result;

  if (!$res->is_success) {
    return undef, qq[Failed to access ] . $json->{endpoint};
  }

  # They come in params as "" for checked and undef for unchecked
  $json->{cert_alerts}    = defined $json->{cert_alerts};
  $json->{receive_emails} = defined $json->{receive_emails};

  return $json, undef;
}

1;

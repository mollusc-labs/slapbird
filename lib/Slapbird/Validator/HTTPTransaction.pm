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


package Slapbird::Validator::HTTPTransaction;

use strict;
use warnings;

use feature 'state';
use Slapbird::Enum::ApplicationTypes;

sub validate {
  my ($class, $object) = @_;

  my $jv = JSON::Validator->new();

  $jv->schema({
    type     => 'object',
    required => [
      'type',      'method',        'end_point',    'start_time',
      'end_time',  'response_code', 'request_size', 'error',
      'requestor', 'handler'
    ],
    properties => {
      type =>
        {type => 'string', enum => [Slapbird::Enum::ApplicationTypes->all]},
      method        => {type => 'string'},
      end_point     => {type => 'string'},
      start_time    => {type => 'number'},
      end_time      => {type => 'number'},
      response_code =>
        {type => ['integer', 'string'], minimum => 100, maximum => 599},
      response_size => {type => ['integer', 'string', 'null']},
      request_size  => {type => ['integer', 'string', 'null']},
      handler       => {type => ['string',  'null']},
      error         => {type => ['string',  'null']},
      requestor     => {type => ['string',  'null']},
      num_queries   => {type => ['integer', 'null']},
      queries       => {
        type  => 'array',
        items => {
          additionalProperties => 0,
          properties           => {
            total_time => {type => ['number', 'string']},
            sql        => {type => 'string'}
          }
        }
      },
      request_headers  => {type => 'object'},
      response_headers => {type => 'object'},
      stack            => {
        type  => 'array',
        items => {
          additionalProperties => 0,
          properties           => {
            start_time => {type => 'number'},
            end_time   => {type => 'number'},
            name       => {type => 'string'}
          },
          required => ['start_time', 'end_time', 'name']
        }
      },
      os => {type => ['string', 'null']}
    }
  });

  my @errors = $jv->validate($object);
  return @errors                         if @errors;
  return $class->_validate_mojo($object) if $object->{type} eq 'mojo';
  return ();
}

sub _validator_mojo {
  my ($class) = @_;

  state $jv;

  return $jv if $jv;

  $jv = JSON::Validator->new();

  $jv->schema({
    type       => 'object',
    required   => ['request_id'],
    properties => {request_id => {type => 'string'},}
  });

  return $jv;
}

sub _validate_mojo {
  my ($class, $object) = @_;
  return $class->_validator_mojo->validate($object);
}

1;

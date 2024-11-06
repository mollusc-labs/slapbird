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


package Slapbird::Action::DecodeStripeEvent;

use Moo;
use Types::Standard qw(Str);
use Encode;

has payload => (is => 'ro', isa => Str, required => 1);
has header  => (is => 'ro', isa => Str, required => 1);
has _schema => (is => 'ro', isa => Str, default  => sub {'v1'});

sub execute {
  my ($self) = @_;

  my $decoded_payload = Encode::decode('utf8', $self->payload);
  my $decoded_header  = Encode::decode('utf8', $self->payload);

  my @signatures;
  my $timestamp = -1;

  for (split(',', $decoded_header)) {
    my ($key, $value) = split('=', $_);

    if ($key eq 't') {
      $timestamp = 0 + $value;
    }

    if ($key eq $self->_schema) {
      push @signatures, $value;
    }
  }

  if ($timestamp == -1) {
    return (undef, 'Unable to extract timestamp and signature from header');
  }

  if (!@signatures) {
    return (undef, 'No signatures found with schema');
  }
}

1;

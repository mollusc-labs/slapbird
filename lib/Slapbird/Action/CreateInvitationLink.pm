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


package Slapbird::Action::CreateInvitationLink;

use Moo;
use URL::Encode     qw(url_decode_utf8);
use Crypt::JWT      qw(encode_jwt decode_jwt);
use Time::HiRes     qw(time);
use Types::Standard qw(Str);
use MIME::Base64;

has user_pricing_plan_id => (is => 'ro', isa => Str, required => 1);
has secure_key           => (is => 'ro', isa => Str, required => 1);

sub execute {
  my ($self) = @_;

  my $invitation_link      = '/invite/';
  my $user_pricing_plan_id = $self->user_pricing_plan_id;
  my $valid_until          = time + 3_600;
  my $invitation_code      = encode_jwt(
    payload =>
      qq/{"user_pricing_plan_id": "$user_pricing_plan_id", "valid_until": $valid_until}/,
    alg => 'HS256',
    key => $self->secure_key
  );

  $invitation_link .= encode_base64($invitation_code);

  return $invitation_link;
}

1;

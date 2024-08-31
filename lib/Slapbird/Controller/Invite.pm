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


package Slapbird::Controller::Invite;

use Mojo::Base 'Mojolicious::Controller';
use MIME::Base64;
use Crypt::JWT  qw(encode_jwt decode_jwt);
use Time::HiRes qw(time);

sub invite {
  my ($c) = @_;

  my $jwt = decode_base64($c->param('invite_code'));
  my $data
    = decode_jwt(token => $jwt, key => $c->secure_key, decode_payload => 1);

  unless ($data || $data->{valid_until} <= time) {
    $c->flash_danger('That invite is no longer valid.');
    return $c->redirect_to('/');
  }

  $c->debug($data);

  $c->session(plan_to_join => $data->{user_pricing_plan_id});

  if ($c->logged_in) {
    if ($c->user->user_pricing_plan->user_pricing_plan_id eq
      $data->{user_pricing_plan_id})
    {
      $c->flash_danger("You're already in that plan!");
      return $c->redirect_to('/dashboard');
    }
    return $c->redirect_to('/dashboard/confirm-join-plan');
  }

  return $c->redirect_to('/login/github');
}

1;

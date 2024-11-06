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


package Slapbird::Mojolicious::Sessions;

use Mojo::Base 'Mojolicious::Sessions';

use Mojo::JSON;
use Mojo::Util qw(b64_decode b64_encode);

sub store {
  my ($self, $c) = @_;

  # Make sure session was active
  my $stash = $c->stash;
  return unless my $session = $stash->{'mojo.session'};
  return unless keys %$session || $stash->{'mojo.active_session'};

  # Don't reset flash for static files
  my $old = delete $session->{flash};
  $session->{new_flash} = $old if $stash->{'mojo.static'};
  delete $session->{new_flash} unless keys %{$session->{new_flash}};

  # Generate "expires" value from "expiration" if necessary
  my $expiration = $session->{expiration} // $self->default_expiration;
  my $default    = delete $session->{expires};
  $session->{expires} = $default || time + $expiration if $expiration || $default;

  my $value = b64_encode $self->serialize->($session), '';
  $value =~ y/=/-/;
  my $options = {
    domain   => $self->cookie_domain,
    expires  => $session->{expires},
    httponly => 0,
    path     => $self->cookie_path,
    samesite => $self->samesite,
    secure   => $self->secure
  };
  $c->signed_cookie($self->cookie_name, $value, $options);
}

1;
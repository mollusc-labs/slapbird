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
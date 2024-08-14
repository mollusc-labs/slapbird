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

  if ($c->user->user_pricing_plan->user_pricing_plan_id eq
    $data->{user_pricing_plan_id})
  {
    $c->flash_danger("You're already in that plan!");
    return $c->redirect_to('/dashboard');
  }

  if ($c->logged_in) {
    return $c->redirect_to('/dashboard/confirm-join-plan');
  }

  return $c->redirect_to('/login/github');
}

1;

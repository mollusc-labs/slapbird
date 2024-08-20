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

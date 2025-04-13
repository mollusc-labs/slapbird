package Slapbird::Action::SendEmail;

use Moo;
use Types::Standard qw(HashRef Str);
use Const::Fast;
use Mojo::UserAgent;
use Mojo::URL;

has to      => (is => 'ro', required => 1, isa => Str);
has from    => (is => 'ro', isa => Str, default => 'no-reply@slapbirdapm.com');
has subject => (is => 'ro', required => 1, isa => Str);
has body    => (is => 'ro', required => 1, isa => Str);

const my $email_api_key => $ENV{SLAPBIRD_EMAIL_API_KEY};
const my $email_api_uri => $ENV{SLAPBIRD_EMAIL_API_URI};
const my $ua            => Mojo::UserAgent->new;

sub execute {
  my ($self) = @_;

  my $url   = Mojo::URL->new($email_api_uri)->userinfo("api:" . $email_api_key);
  my $email = {
    from    => $self->from,
    to      => $self->to,
    subject => $self->subject,
    text    => $self->body
  };

  if (!$ENV{SLAPBIRD_PRODUCTION} && !$ENV{SLAPBIRD_TEST_EMAIL}) {
    use DDP;
    CORE::say 'Would have sent email:';
    p $email;
    return $email;
  }

  my $result = $ua->post(
    $url,
    {Accept => '*/*', Authorization => "Bearer $email_api_key"},
    form => $email
  )->result;

  if (!$result->is_success) {
    return undef;
  }

  return $email;
}

1;

package Slapbird::Client::Github;

use Moo;
use Types::Standard qw(Str);
use Mojo::UserAgent;

has base_uri => (
  is      => 'ro',
  isa     => Str,
  default => sub { return 'https://api.github.com' }
);

has ua => (is => 'ro', default => sub { return Mojo::UserAgent->new; });

sub _request {
  my ($self, $method, $location, @args) = @_;
  return $self->ua->$method($self->base_uri . $location, @args)->result;
}

sub _make_headers {
  my ($self, $access_token) = @_;

  return +{
    Authorization          => "Bearer $access_token",
    'X-GitHub-Api-Version' => '2022-11-28',
    Accept                 => 'application/vnd.github+json'
  };
}

sub get_user_emails {
  my ($self, $access_token) = @_;

  my $headers = $self->_make_headers($access_token);
  return $self->_request('get', '/user/emails', $headers);
}

sub get_user_info {
  my ($self, $access_token) = @_;

  my $headers = $self->_make_headers($access_token);
  return $self->_request('get', '/user', $headers);
}

sub get_user_repositories {
  my ($self, $access_token) = @_;

  my $headers = $self->_make_headers($access_token);
  return $self->_request('get', '/user/repos', $headers);
}

sub check_repo_exists {
  my ($self, $access_token, $repository) = @_;
  my $headers = $self->_make_headers($access_token);
  return $self->_request('get', "/repos/$repository", $headers);
}

1;

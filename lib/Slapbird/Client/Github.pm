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

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


package Slapbird::Action::RenameApplication;

use Moo;
use Types::Standard qw(Str);
use Slapbird::Util  qw(slugify);

has schema         => (is => 'ro', required => 1);
has application_id => (is => 'ro', isa      => Str);
has new_name       => (is => 'ro', isa      => Str);

sub execute {
  my ($self) = @_;
  my $application = $self->schema->resultset('Application')
    ->find({application_id => $self->application_id});
  my $slug = slugify($self->new_name);

  if (!$application) {
    return undef;
  }

  $application->update({name => $self->new_name, slug => $slug});

  return $application;
}

1;

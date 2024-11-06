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


package Slapbird::Actions;

use strict;
use warnings;

use Moo::HandleMoose;
use Mojo::Util qw(monkey_patch);
use Mojo::File;
use String::CamelCase qw(decamelize);
use Try::Tiny;
use Carp;

register_action('Slapbird::Action::' . $_)
  for (map {s/\.pm//grxm}
  map { $_->basename } @{Mojo::File->new('lib/Slapbird/Action')->list});

my %actions;

sub register_action {
  my ($class, $name) = @_;

  if (!$name) {
    my $c = $class;
    $c =~ s/Slapbird::Action//gxm;
    $c =~ s/:://gxm;
    $name = decamelize($c);
  }

  return $actions{$name} = $class;
}

sub actions {
  return \%actions;
}

sub helper {
  my ($class, $c) = @_;

# All actions in Slapbird::Action::* are turned into snake case methods of the Slapbird::Action class.
  for my $k (keys %actions) {
    eval "use $actions{$k}";
    Carp::cluck($@) if ($@);
    monkey_patch(
      $class, $k,
      sub {
        shift;    # Remove controller
        my %args = (@_);
        my $meta = Moo::HandleMoose::inject_real_metaclass_for($actions{$k});

        if (defined $meta->find_attribute_by_name('schema')) {
          $args{schema} //= $c->dbic;
        }

        if (defined $meta->find_attribute_by_name('stripe')) {
          $args{stripe} //= $c->stripe;
        }

        return $actions{$k}->new(%args)->execute();
      }
    );
  }

  return sub {
    $class;
  };
}

1;

package Slapbird::Actions;

use Moo;
use Moo::HandleMoose;
use Mojo::Util qw(monkey_patch);
use Mojo::File;
use String::CamelCase qw(decamelize);
use Try::Tiny;
use Carp;

register_action('Slapbird::Action::' . $_->basename)
  for (@{Mojo::File->new('lib/Slapbird/Action')->list});

my %actions;

sub register_action {
  my ($class, $name) = @_;

  $class =~ s/\.pm//g;

  if (!$name) {
    my $c = $class;
    $c =~ s/Slapbird::Action//g;
    $c =~ s/:://g;
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

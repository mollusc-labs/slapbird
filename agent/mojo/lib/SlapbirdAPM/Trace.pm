package SlapbirdAPM::Trace;

use strict;
use warnings;

my $logger;

# set a callback sub for logging
sub callback {
  shift if @_ > 1;

  my $coderef = shift;
  unless (ref($coderef) eq 'CODE' and defined(&$coderef)) {
    require Carp;
    Carp::croak("$coderef is not a code reference!");
  }

  $logger = $coderef;
}

# where logging actually happens
sub _log_call {
  my %args = @_;
  $logger->($args{name}, $args{args}, $args{'sub'});
}

sub trace_pkgs {
  my $class = shift;
  _wrap_symbols(@_);
}

sub trace_subs {
  my ($class, @tracers) = @_;

  for (@tracers) {
    no strict 'refs';
    no warnings;
    my $sub = *{$_}{CODE};
    next unless defined $sub and defined &$sub;
    *{$_} = sub {
      return _log_call(name => "$_", args => [@_], 'sub' => $sub);
    };
  }
}

sub _wrap_symbols {
  my (@traces) = @_;

  my %seen = (map { ($_ => 1) } @traces);

  while (my $traced = shift @traces) {
    my $src;

    no strict 'refs';

    # get the calling package symbol table name
    {
      no strict 'refs';
      $src = \%{$traced . '::'};
    }

    # loop through all symbols in calling package, looking for subs
    for my $symbol (keys %$src) {

      # get all code references, make sure they're valid
      my $sub = *{$traced . '::' . $symbol}{CODE};
      next unless defined $sub and defined &$sub;

      {
        no warnings;
        *{${traced} . '::' . $symbol} = sub {
          return _log_call(name => "${traced}::$symbol", args => [@_], 'sub' => $sub);
        };
      };
    }
  }
}

1;
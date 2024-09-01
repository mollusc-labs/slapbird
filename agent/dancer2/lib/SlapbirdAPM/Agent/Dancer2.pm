package SlapbirdAPM::Agent::Dancer2;

use strict;
use warnings;

our $VERSION = '0.003';

1;

=pod

=encoding utf8

=head1 NAME

SlapbirdAPM::Agent::Mojo

The L<SlapbirdAPM|https://www.slapbirdapm.com> user-agent for L<Mojolicious> applications.

=head1 SYNOPSIS

=over 2

=item *

Create an application on L<SlapbirdAPM|https://www.slapbirdapm.com>

=item *

Install this ie C<cpanm SlapbirdAPM::Agent::Dancer2>, C<cpan -I SlapbirdAPM::Agent::Dancer2>

=item *

Add C<use Dancer2::Plugin::SlapbirdAPM> to your L<Dancer2> application

=item *

Add your API key to your environment: C<SLAPBIRDAPM_API_KEY="$api_key">

=item *

Restart your application

=back

=head1 EXAMPLE

  use strict;
  use warnings;
  
  use Dancer2;
  
  BEGIN {
  # would usually be in config.yml
    set plugins => {SlapbirdAPM => {key => '<my-api-key>'}};
  }
  
  use Dancer2::Plugin::SlapbirdAPM;
  
  get '/' => sub {
     'Hello World!';
  };
  
  dance;

=head1 SEE ALSO

L<SlapbirdAPM::Agent::Plack>

L<SlapbirdAPM::Agent::Mojo>

=head1 AUTHOR

Mollusc Labs, C<https://github.com/mollusc-labs>

=head1 LICENSE

SlapbirdAPM::Agent::Dancer2 like all SlapbirdAPM user-agents is licensed under the MIT license.

SlapbirdAPM (the website) however, is licensed under the GNU AGPL version 3.0.

package SlapbirdAPM::Agent::Plack;

use strict;
use warnings;

our $VERSION = '0.004';

1;

=pod

=encoding utf8

=head1 NAME

SlapbirdAPM::Agent::Plack

The L<SlapbirdAPM|https://www.slapbirdapm.com> user-agent for L<Plack> applications.

=head1 SYNOPSIS

=over 2

=item *

Create an application on L<SlapbirdAPM|https://www.slapbirdapm.com>

=item *

Install this ie C<cpanm SlapbirdAPM::Agent::Plack>, C<cpan -I SlapbirdAPM::Agent::Plack>

=item *

Add C<enable 'SlapbirdAPM';> to your L<Plack::Builder> statement

=item *

Add your API key to your environment: C<SLAPBIRDAPM_API_KEY="$api_key">

=item *

Restart your application

=back

=head1 EXAMPLE

This example uses a L<Dancer2> application, but you can substitute for any L<Plack> application.

  use strict;
  use warnings;
  
  use Dancer2;
  use Plack::Builder;
  
  get '/' => sub {
    'Hello World';
  };
  
  builder {
    enable 'SlapbirdAPM', key => '01J5GY4NF3TDDDNFJZJDDMB8CRmy-plack-app';
    app;
  };

=head1 SEE ALSO

L<SlapbirdAPM::Agent::Mojo>

L<SlapbirdAPM::Agent::Dancer2>

=head1 AUTHOR

Mollusc Labs, C<https://github.com/mollusc-labs>

=head1 LICENSE

SlapbirdAPM::Agent::Plack like all SlapbirdAPM user-agents is licensed under the MIT license.

SlapbirdAPM (the website) however, is licensed under the GNU AGPL version 3.0.

=cut

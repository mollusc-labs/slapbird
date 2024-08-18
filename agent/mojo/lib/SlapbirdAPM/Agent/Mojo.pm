package SlapbirdAPM::Agent::Mojo;

use strict;
use warnings;

our $VERSION = 0.003;

1;

=pod

=encoding utf8

=head1 SlapbirdAPM::Agent::Mojo

The L<SlapbirdAPM|https://www.slapbirdapm.com> user-agent for Mojolicious applications.

=head2 Quick start

=over 2

=item Create an application on L<SlapbirdAPM|https://www.slapbirdapm.com>

=item Install this ie C<cpanm SlapbirdAPM::Agent::Mojo>, C<cpan -I SlapbirdAPM::Agent::Mojo>

=item Add C<plugin 'SlapbirdAPM';> to your project

=item Add your API key to your environment: C<SLAPBIRDAPM_API_KEY="MY API KEY">

=item Restart your application

=back

=head2 Licensing

SlapbirdAPM::Agent::Mojo like all SlapbirdAPM user-agents is licensed under the MIT license.

SlapbirdAPM (the website) however, is licensed under the GNU AGPL version 3.0.

=cut

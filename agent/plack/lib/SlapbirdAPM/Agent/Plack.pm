package SlapbirdAPM::Agent::Plack;

use strict;
use warnings;

our $VERSION = '0.001';

1;

=pod

=encoding utf8

=head1 SlapbirdAPM::Agent::Plack

The L<SlapbirdAPM|https://www.slapbirdapm.com> user-agent for Plack applications.

=head2 Quick start

=over 2

=item Create an application on L<SlapbirdAPM|https://www.slapbirdapm.com>

=item Install this ie C<cpanm SlapbirdAPM::Agent::Plack>, C<cpan -I SlapbirdAPM::Agent::Plack>

=item Add C<enable 'SlapbirdAPM';> to your L<PlacK::Builder> statement

=item Add your API key to your environment: C<SLAPBIRDAPM_API_KEY="$api_key">

=item Restart your application

=back

=head2 Licensing

SlapbirdAPM::Agent::Mojo like all SlapbirdAPM user-agents is licensed under the MIT license.

SlapbirdAPM (the website) however, is licensed under the GNU AGPL version 3.0.

=cut

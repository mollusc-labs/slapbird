package SlapbirdAPM::Agent::Catalyst;

use strict;
use warnings;

our $VERSION = '0.1';

1;

=pod

=encoding utf8

=head1 NAME

SlapbirdAPM::Agent::Catalyst

The L<SlapbirdAPM|https://www.slapbirdapm.com> user-agent for L<Catalyst> applications.

=head1 SYNOPSIS

=over 2

=item *

Create an application on L<SlapbirdAPM|https://www.slapbirdapm.com>

=item *

Install this ie C<cpanm SlapbirdAPM::Agent::Catalyst>, C<cpan -I SlapbirdAPM::Agent::Catalyst>

=item *

Add C<use Catalyst qw/SlapbirdAPM/;> to your L<Catalyst> application

=item *

Add your API key to your environment: C<SLAPBIRDAPM_API_KEY="$api_key">

=item *

Restart your application

=back

=head1 EXAMPLE

    package MyApp;

    use Catalyst qw/
        SlapbirdAPM
    /;

This will automatically begin monitoring your application if the C<SLAPBIRDAPM_API_KEY> environment
variable is set to your SlapbirdAPM key.

=head1 SEE ALSO

L<SlapbirdAPM::Agent::Mojo>

L<SlapbirdAPM::Agent::Plack>

L<SlapbirdAPM::Agent::Dancer2>

=head1 AUTHOR

Mollusc Labs, C<https://github.com/mollusc-labs>

=head1 LICENSE

SlapbirdAPM::Agent::Catalyst like all SlapbirdAPM user-agents is licensed under the MIT license.

SlapbirdAPM (the website) however, is licensed under the GNU AGPL version 3.0.

=cut

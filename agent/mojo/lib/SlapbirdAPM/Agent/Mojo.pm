package SlapbirdAPM::Agent::Mojo;

use strict;
use warnings;

our $VERSION = 0.008;

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

Install this ie C<cpanm SlapbirdAPM::Agent::Mojo>, C<cpan -I SlapbirdAPM::Agent::Mojo>

=item *

Add C<plugin 'SlapbirdAPM';> to your L<Mojolicious> application

=item *

Add your API key to your environment: C<SLAPBIRDAPM_API_KEY="$api_key">

=item *

Restart your application

=back

=head1 EXAMPLE

  use strict;
  use warnings;
  
  use Mojolicious::Lite -signatures;
  
  plugin 'SlapbirdAPM', key => '01J5H5BGE14WCZ3QKQA1AQ704Jabcv';
  
  get '/' => sub {
    my ($c) = @_;
    return $c->render(text => 'Hello World!');
  };
  
  app->start;

=head1 SEE ALSO

L<SlapbirdAPM::Agent::Plack>

=head1 AUTHOR

Mollusc Labs, C<https://github.com/mollusc-labs>

=head1 LICENSE

SlapbirdAPM::Agent::Mojo like all SlapbirdAPM user-agents is licensed under the MIT license.

SlapbirdAPM (the website) however, is licensed under the GNU AGPL version 3.0.

=cut

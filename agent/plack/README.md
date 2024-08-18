# SlapbirdAPM::Agent::Plack

The [SlapbirdAPM](https://www.slapbirdapm.com) user-agent for Plack applications.

## Quick start

1. Create an application on [SlapbirdAPM](https://www.slapbirdapm.com)
2. Install this ie `cpanm SlapbirdAPM::Agent::Plack` or `cpan -I SlapbirdAPM::Agent::Plack`
3. Add `enable 'SlapbirdAPM` to your `Plack::Builder` statement
4. Add your API key to your environment: `SLAPBIRDAPM_API_KEY=<MY API KEY>`
5. Restart your application

## Licensing

SlapbirdAPM::Agent::Plack like all SlapbirdAPM user-agents is licensed under the MIT license.

SlapbirdAPM (the server side software) however, is licensed under the GNU AGPL version 3.0.

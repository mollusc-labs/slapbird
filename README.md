<p align="center">
	<a href="https://slapbird.co">
    <img width="130" height="120" src="https://github.com/rawleyfowler/slapbird/assets/75388349/bfbee229-59e9-44ea-9249-8707af4322b0"/>
	</a>
</p>
<h1 align="center"><a href="https://www.slapbirdapm.com">SlapBird</a></h1>
<p align="center">
  An all <b>Perl</b> APM for Mojolicious, Plack, and soon, Dancer2.
</p>

## Beta notice

SlapbirdAPM is currently in a BETA state. There will be bugs, things may break, docs may lack,
but at its core the system works!

### Getting started

1. Login to [SlapbirdAPM](https://www.slapbirdapm.com)
2. Sign-in with an OAuth2 provider
3. Create an application, and copy your API key
4. Install `SlapbirdAPM::Agent::Mojo` via CPAN
5. Add the following line to your application `plugin('SlapbirdAPM', key => "$YOUR_API_KEY")`
6. Optionally, use `plugin('SlapbirdAPM')` and the `SLAPBIRDAPM_API_KEY` env var, instead

### Copyright & Legalities

SlapbirdAPM &copy; Mollusc Labs Inc. 2024

SlapbirdAPM web application is provided under the [GNU Affero General Public License version 3.0](https://www.gnu.org/licenses/agpl-3.0.en.html).

SlapbirdAPM agents are provided under the [MIT license](https://opensource.org/license/mit).

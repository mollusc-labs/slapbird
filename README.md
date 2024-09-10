<p align="center">
	<a href="https://slapbird.co">
    <img width="130" height="120" src="https://github.com/rawleyfowler/slapbird/assets/75388349/bfbee229-59e9-44ea-9249-8707af4322b0"/>
	</a>
</p>
<h1 align="center"><a href="https://www.slapbirdapm.com">SlapBird</a></h1>
<p align="center">
  An all <b>Perl</b> APM for Mojolicious, Plack, and Dancer2
</p>

### Getting started

1. Login to [SlapbirdAPM](https://www.slapbirdapm.com)
2. Sign-in with an OAuth2 provider
3. Create an application, and copy your API key
4. Install `SlapbirdAPM::Agent::Mojo` via CPAN
5. Add the following line to your application `plugin('SlapbirdAPM', key => "$YOUR_API_KEY")`
6. Optionally, use `plugin('SlapbirdAPM')` and the `SLAPBIRDAPM_API_KEY` env var, instead

### Hacking on the Slapbird application

#### Pre-reqs

1. Perl >= `5.36`
2. `podman`

##### Running the app for the first time

```sh
cp .env.example .env
vim .env # fill out the GITHUB_* fields with OAuth app information: https://github.com/settings/developers
bin/podman_dev_db
bin/podman_dev_memcached # optional
bin/run_migrations up # you may have to wait for the database to begin accepting connections
bin/install_deps
morbo app.pl
```

*note*: `morbo` will hot-reload the app on changes.

##### Running the app

```sh
bin/podman_dev_db
bin/podman_dev_memcached # optional
bin/run_migrations up # you may have to wait for the database to begin accepting connections
morbo app.pl
```

*note*: `morbo` will hot-reload the app on changes.

##### Testing

```sh
prove -rlv -Ilib t/
```

##### Contributing

Perl code is to be formatted with the `.perltidyrc` in the root of the project, `Perl::Critic` with `PBP`
is to be followed as well. If you need to break a `Perl::Critic` rule, leave a comment ie: 

```
## Disabled because ...
## no critic [foo]
```

All PR's should be submitted as a single commit.

### Hacking on Slapbird agents

All agents are available in the `agent/` directory.

##### Testing an agent

```
cd agent/mojo
perl Makefile.PL
make
make test
```

##### Installing an agent locally

```
cd agent/mojo
perl Makefile.PL
make
make test
make install
```

Then when you run a local application using the agent, to hit your local SlapbirdAPM instance add the following environment variables:

```
SLAPBIRD_APM_DEV=1
SLAPBIRD_APM_URI=http://localhost:3000
```

If you don't set these, your agent will hit production instead. (You'll see 401's if you made your API key locally and forgot to set these)

### Copyright & Legalities

SlapbirdAPM &copy; Mollusc Labs Inc. 2024

SlapbirdAPM web application is provided under the [GNU Affero General Public License version 3.0](https://www.gnu.org/licenses/agpl-3.0.en.html).

SlapbirdAPM agents are provided under the [MIT license](https://opensource.org/license/mit).

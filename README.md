<p align="center">
	<a href="https://slapbirdapm.com">
    <img width="130" height="120" src="https://github.com/rawleyfowler/slapbird/assets/75388349/bfbee229-59e9-44ea-9249-8707af4322b0"/>
	</a>
</p>
<h1 align="center"><a href="https://www.slapbirdapm.com">SlapbirdAPM</a></h1>
<p align="center">
  A free, and open-source, application observability platform for Perl web applications.
</p>

### Getting started

1. Login to [SlapbirdAPM](https://www.slapbirdapm.com)
2. Sign-in with an OAuth2 provider
3. Create an application, and copy your API key
4. Install the agent software for your application
6. Set the `SLAPBIRDAPM_API_KEY` environment variable to your API key

### Finding clients

SlapbirdAPM is a *multi-language* observability platform. We officially support
`perl`, `raku`, and (soon) `ruby`. But un-official clients can be used, or, you can write your own.

#### Writing your own client

Check out our [Mojo Client](https://github.com/mollusc-labs/slapbird/tree/main/agent/mojo) as an example.

### Hacking on the Slapbird application

#### Pre-reqs

1. Perl >= `5.36`
2. `podman`
3. cpanminus ie `cpan -I App::cpanminus`

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

All official are available in the `agent/` directory.

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

SlapbirdAPM &copy; Mollusc Labs. 2025

SlapbirdAPM web application is provided under the [GNU Affero General Public License version 3.0](https://www.gnu.org/licenses/agpl-3.0.en.html).

Official slapbirdAPM agents are provided under the [MIT license](https://opensource.org/license/mit).

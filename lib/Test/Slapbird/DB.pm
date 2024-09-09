package Test::Slapbird::DB;

use strict;
use warnings;

use Test::Slapbird;

use Carp ();
use Exporter 'import';
use Mojo::Pg;
use Slapbird::Schema;

our @EXPORT = qw(test_dbh test_schema);

my $already_run;
my ($has_podman, $has_docker);

sub _db_init {
  if (!$has_podman || !$has_docker) {
    $has_podman = `sh -c 'command -v podman'`;
    $has_docker = `sh -c 'command -v docker'`;
  }

  return if $already_run;

  if (!$has_podman && !$has_docker) {
    Carp::carp(
      'Neither podman, nor docker run. Assuming you have your own database...');

    if (!$ENV{SLAPBIRD_GITHUB_ACTION}) {
      Carp::croak(
        'Neither podman, nor docker available, and this is not a Github action, cannot test.'
      );
    }

    if ($ENV{SLAPBIRD_GITHUB_ACTION}) {
      system(q[SLAPBIRD_ENV='../../.env.github-actions bin/run_migrations up]);
    }
    goto DONE;
  }

  if ($has_podman) {
    unless (system(q[podman start slapbird-postgres-test])) {
      goto DONE;
    }

    Carp::croak('Failed to invoke podman when spinning up test database: '
        . $?
        . "\n Perhaps you need to run 'podman pull docker.io/library/postgres:15-alpine'"
      )
      if system(q[
podman run --replace \
  --name slapbird-postgres-test \
  -e POSTGRES_USER=slapbird \
  -e POSTGRES_PASSWORD=password \
  -p 5432:5432 \
  -d \
  postgres:15-alpine
]);
  }
  else {
    unless (system(q[docker start slapbird-postgres-test])) {
      goto DONE;
    }

    Carp::croak('Failed to invoke docker when spinning up test database: ' . $?)
      if system(q[
docker run --replace \
 --name slapbird-postgres-test \
  -e POSTGRES_USER=slapbird \
  -e POSTGRES_PASSWORD=password \
  -p 5432:5432 \
  -d \
  postgres:15-alpine
]);
  }

DONE:

  if ($has_podman) {
    system(q[
until podman exec \
  -it slapbird-postgres-test \
    pg_isready \
    -U slapbird \
    -h localhost; do sleep 1; done
]);
    system(
      q[podman exec -it slapbird-postgres-test createdb -U slapbird slapbird]);
  }
  elsif ($has_docker) {
    system(q[
until docker run \
  --rm \
  --link slapbird-postgres-test \
  postgres:15-alpine pg_isready \
    -U slapbird \
    -h localhost; do sleep 1; done
]);
    system(
      q[podman exec -it slapbird-postgres-test createdb -U slapbird slapbird]);
  }

  system(q[bin/run_migrations up]) unless $ENV{SLAPBIRD_GITHUB_ACTION};

  return $already_run = 1;
}

END {
  if ($has_podman) {
    eval { system(qq[podman kill slapbird-postgres-test]); };
  }

  if ($has_docker) {
    eval { system(qq[docker kill slapbird-postgres-test]) };
  }
}


_db_init();

sub test_dbh {
  if ($ENV{SLAPBIRD_GITHUB_ACTION}) {
    return Mojo::Pg->new(
      'postgres://slapbird:password@slapbird-postgres-test/slapbird')->db->dbh;
  }

  return Mojo::Pg->new('postgres://slapbird:password@localhost/slapbird')
    ->db->dbh;
}

sub test_schema {
  return Slapbird::Schema->connect(sub { test_dbh()->dbh });
}

1;

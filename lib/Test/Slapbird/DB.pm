package Test::Slapbird::DB;

use strict;
use warnings;

use Test::Slapbird;

use Carp ();

my $already_run;
my ($has_podman, $has_docker);

sub db_init {
  if (!$has_podman || !$has_docker) {
    $has_podman = `sh -c 'command -v podman'`;
    $has_docker = `sh -c 'command -v docker'`;
  }

  return if $already_run;

  if (!$has_podman && !$has_docker) {
    Carp::carp(
      'Neither podman, nor docker run. Assuming you have your own database...');
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
  -e POSTGRES_DB=slapbird \
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
  -e POSTGRES_DB=slapbird \
  -p 5432:5432 \
  -d \
  postgres:15-alpine
]);
  }

DONE:

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


db_init();

1;

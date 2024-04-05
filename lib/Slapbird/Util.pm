package Slapbird::Util;

# Slapbird  Copyright (C) 2024  Rawley Fowler, Mollusc Labs
# This program comes with ABSOLUTELY NO WARRANTY; for details type `show w'.
# This is free software, and you are welcome to redistribute it
# under certain conditions; type `show c' for details.

use strict;
use warnings;

use Exporter qw(import);

our @EXPORT_OK = qw(
  bad_request_json
  bad_request_html
  unauthorized_json
  unauthorized_html
);

sub bad_request_json {
  my ($c, $msg) = @_;

  return $c->render(
    status => 400,
    json => { status => 400, msg => $msg }
  );
}

sub bad_request_html {
  my ($c, $msg) = @_;

  return $c->render(
    status => 400,
    template => 'util/bad_request', 
    msg => $msg
  );
}

sub unauthorized_json {
  my ($c) = @_;

  return $c->render(
    status => 401,
    json => { status => 401, msg => 'Unauthorized' }
  );
}

sub unauthorized_html {
  my ($c) = @_;

  return $c->render(
    status => 401,
    template => 'util/unauthorized'
  );
}

1;
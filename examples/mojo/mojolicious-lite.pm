#!/usr/bin/env perl

use strict;
use warnings;

use Mojolicious::Lite -signatures;

plugin 'SlapbirdAPM', key => '';

get '/' => sub {
  my ($c) = @_;
  return $c->render(text => 'Hello World!');
};

app->start;

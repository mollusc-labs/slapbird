#!/usr/bin/env perl

use strict;
use warnings;

use Mojolicious::Lite -signatures;

plugin 'SlapbirdAPM', key => '01J5H5BGE14WCZ3QKQA1AQ704Jabcv';

get '/' => sub {
  my ($c) = @_;
  return $c->render(text => 'Hello World!');
};

app->start;

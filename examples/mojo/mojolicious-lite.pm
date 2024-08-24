#!/usr/bin/env perl

use strict;
use warnings;

use Mojolicious::Lite -signatures;

plugin 'SlapbirdAPM', key => '01J632K1EXTPN4AQDDN76MQN25abc';

get '/' => sub {
  my ($c) = @_;
  return $c->render(text => 'Hello World!');
};

app->start;

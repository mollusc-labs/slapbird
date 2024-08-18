#!/usr/bin/env perl

use strict;
use warnings;

use Plack::Builder;

my $app = sub {
  return [200, 'Hello world', ['Content-Type' => 'text/html']];
};

builder {
  enable 'SlapbirdAPM', key => '01J5GY4NF3TDDDNFJZJDDMB8CRmy-plack-app';
  $app;
};

#!/usr/bin/env perl

use strict;
use warnings;

use Plack::Builder;

my $app = sub {
  return [200, 'Hello world', ['Content-Type' => 'text/html']];
};

builder {
  enable 'SlapbirdAPM', key => '<YOUR API KEY>';
  $app;
};

#!/usr/bin/env perl

use strict;
use warnings;

use Dancer2;
use Plack::Builder;

get '/' => sub {
  'Hello World';
};

builder {
  enable 'SlapbirdAPM', key => '01J5GY4NF3TDDDNFJZJDDMB8CRmy-plack-app';
  app;
};

#!/usr/bin/env perl

use strict;
use warnings;

use Dancer2;

set plugins => {SlapbirdAPM => {key => 'my_key'},};

get '/' => sub {
  'Hello World';
};

dance;

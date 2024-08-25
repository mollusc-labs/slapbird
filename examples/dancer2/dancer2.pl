use strict;
use warnings;

use Dancer2;
use Dancer2::Plugin::SlapbirdAPM;

BEGIN {
  set plugins => {Slapbird =>};
}

set port => 3030;

get '/' => sub {
  'Hello World';
};

get '/foo' => sub {
  'flarb';
};

dance;

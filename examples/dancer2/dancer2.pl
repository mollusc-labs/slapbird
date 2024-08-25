use strict;
use warnings;
use Dancer2;

BEGIN {
# would usually be in config.yml
  set plugins => {SlapbirdAPM => {key => '01J65HDRHG6P0Z9CJ22FG7FMCGd2-app'}};
}

use Dancer2::Plugin::SlapbirdAPM;

set port => 3030;

get '/' => sub {
  'Hello World';
};

get '/foo' => sub {
  'flarb';
};

dance;

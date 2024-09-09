package Test::Slapbird;

use strict;
use warnings;

use Dotenv -load => $ENV{SLAPBIRD_GITHUB_ACTION}
  ? '.env.github-actions'
  : '.env.test';

1;

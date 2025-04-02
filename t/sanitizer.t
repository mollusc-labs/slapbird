use strict;
use warnings;

use lib 'lib';

use Test::More;
use Time::HiRes qw(time);
use Try::Tiny;
use Slapbird::Sanitizer::HTTPTransaction;
use Slapbird::Sanitizer::Stack;
use Slapbird::Sanitizer::Query;

my @stack = (
  {
    start_time => 100_000,
    end_time   => 100_100,
    name       => 'foo::bar',
    total_time => (100_100 - 100_000)
  },
  {
    start_time => 99_999,
    end_time   => 109_999,
    name       => 'dbi::do_stuff',
    total_time => (109_999 - 99_999)
  }
);

my $stack_html = Slapbird::Sanitizer::Stack->sanitize(\@stack);
my $stack_text
  = qq|<div class="slapbird-stack-row"><span class="slapbird-stack-row-name">foo::bar</span> - <span class="slapbird-stack-row-time">100.00</span>ms</div>\n<div class="slapbird-stack-row"><span class="slapbird-stack-row-name">dbi::do_stuff</span> - <span class="slapbird-stack-row-time">10000.00</span>ms</div>|;

is $stack_html, $stack_text, 'is stack properly formatted?';

my @queries = (
  {sql => 'select * from users', total_time => 1},
  {sql => 'select * from users', total_time => 2}
);

my $http_transaction = {
  stack            => \@stack,
  requestor        => 'other_app',
  start_time       => 1725630339761,
  end_time         => 1725631339761,
  error            => "error\nother_error\nanother_error",
  request_headers  => {foo => 'bar'},
  response_headers => {bar => 'baz'},
  queries          => \@queries
};

my $sanitized_transaction
  = Slapbird::Sanitizer::HTTPTransaction->sanitize($http_transaction);

is $sanitized_transaction->{stack}, $stack_text,
  'is stack properly formatted via http_transaction sanitizer?';
is $sanitized_transaction->{total_time},
  sprintf('%.2f', 1725631339761 - 1725630339761), 'is total time correct?';
my $error_text
  = qq|<div class="slapbird-error-row">error</div>\n<div class="slapbird-error-row">other_error</div>\n<div class="slapbird-error-row">another_error</div>|;
is $sanitized_transaction->{error}, $error_text, 'is error text correct?';
is $sanitized_transaction->{request_headers}, 'foo: bar',
  'is request_headers correct?';
is $sanitized_transaction->{response_headers}, 'bar: baz',
  'is request_headers correct?';
is $sanitized_transaction->{queries}->[0]->{total_time}, 2,
  'are queries properly ordered?';

my $error;
my $val = undef;
try {
  $val = Slapbird::Sanitizer::HTTPTransaction->sanitize(undef);
}
catch {
  $error = $_;
};

is $error, undef, 'no error thrown when http transaction sanitize undef?';
is $val,   undef, 'is undef when http transaction sanitize undef?';

try {
  $val = Slapbird::Sanitizer::Stack->sanitize(undef);
}
catch {
  $error = $_;
};

is $error, undef, 'no error thrown when stack sanitize undef?';
is $val,   '', 'is val empty when stack sanitize undef?';

try {
  $val = Slapbird::Sanitizer::Query->sanitize(undef);
}
catch {
  $error = $_;
};

is $error, undef, 'no error thrown when query sanitize undef?';
is $val,   '', 'is val empty when query sanitize undef?';

done_testing;

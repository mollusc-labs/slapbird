use strict;
use warnings;

use lib 'lib';

use Test::More;
use Time::HiRes qw(time);
use Slapbird::Sanitizer::HTTPTransaction;
use Slapbird::Sanitizer::Stack;

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

my $http_transaction = {
  stack            => \@stack,
  requestor        => 'other_app',
  start_time       => 1725630339761,
  end_time         => 1725631339761,
  error            => "error\nother_error\nanother_error",
  request_headers  => {foo => 'bar'},
  response_headers => {bar => 'baz'}
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

done_testing;
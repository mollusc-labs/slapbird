use strict;
use warnings;

use lib 'lib';

use Test::More;
use Time::HiRes qw(time);
use Try::Tiny;
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
is $val,   undef, 'is val still undef when http transaction sanitize undef?';

try {
  $val = Slapbird::Sanitizer::Stack->sanitize(undef);
}
catch {
  $error = $_;
};

is $error, undef, 'no error thrown when stack sanitize undef?';
is $val,   undef, 'is val still undef when stack sanitize undef?';

# Testing for empty stack
my $empty_stack_html = Slapbird::Sanitizer::Stack->sanitize([]);
my $empty_stack_text = '';

is $empty_stack_html, $empty_stack_text, 'is empty stack properly handled?';

# Testing stacks with identical duration
my @identical_duration_stack = (
  {
    start_time => 0,
    end_time => 100,
    name => 'a'
  },
  {
    start_time => 50,
    end_time => 150,
    name => 'b'
  }
);

my $expected_html = qq|<div class="slapbird-stack-row"><span class="slapbird-stack-row-name">a</span> - <span class="slapbird-stack-row-time">100.00</span>ms</div>\n<div class="slapbird-stack-row"><span class="slapbird-stack-row-name">b</span> - <span class="slapbird-stack-row-time">100.00</span>ms</div>|;
my $sanitized_html = Slapbird::Sanitizer::Stack->sanitize(\@identical_duration_stack);

is $sanitized_html, $expected_html, 'is stack properly formatted and ordered with identical durations?';

# Test stack with negative duration
my $neg_duration_stack = {
  start_time => 100,
  end_time => 50,
  name => 'invalid'
};

my $expected_neg_duration_html = qq|<div class="slapbird-stack-row"><span class="slapbird-stack-row-name">invalid</span> - <span class="slapbird-stack-row-time">-50.00</span>ms</div>|;
my $sanitized_neg_duration_html = Slapbird::Sanitizer::Stack->sanitize([$neg_duration_stack]);

is $sanitized_neg_duration_html, $expected_neg_duration_html, 'is stack properly formatted with negative duration?';

# Test missing start_time or end_time
my @missing_time_stack = (
  {
    start_time => 100,
    name => 'missing_end_time'
  },
  {
    end_time => 100,
    name => 'missing_start_time'
  }
 );

my $expected_missing_time_html = qq|<div class="slapbird-stack-row"><span class="slapbird-stack-row-name">missing_end_time</span> - <span class="slapbird-stack-row-time">-100.00</span>ms</div>
<div class="slapbird-stack-row"><span class="slapbird-stack-row-name">missing_start_time</span> - <span class="slapbird-stack-row-time">100.00</span>ms</div>|;
my $sanitized_missing_time_html = Slapbird::Sanitizer::Stack->sanitize(\@missing_time_stack);

is $sanitized_missing_time_html, $expected_missing_time_html, 'is stack properly formatted with missing start or end time?';

# Test with special character in name field - &<>"
my @special_char_stack = (
  {
    start_time => 100,
    end_time => 200,
    name => '<foo> & "bar"'
  }
 );

my $expected_special_char_html = qq|<div class="slapbird-stack-row"><span class="slapbird-stack-row-name">&lt;foo&gt; &amp; &quot;bar&quot;</span> - <span class="slapbird-stack-row-time">100.00</span>ms</div>|;
my $sanitized_special_char_html = Slapbird::Sanitizer::Stack->sanitize(\@special_char_stack);

is $sanitized_special_char_html, $expected_special_char_html, 'is stack properly escaping special chars in name field?';

# Test large number values in start_time and end_time field
my @large_number_stack = (
  {
    start_time => 1_000_000_000_000,
    end_time => 1_000_000_000_100,
    name => 'large_duration'
  }
 );

my $expected_large_num_html = qq|<div class="slapbird-stack-row"><span class="slapbird-stack-row-name">large_duration</span> - <span class="slapbird-stack-row-time">100.00</span>ms</div>|;
my $sanitized_large_num_html = Slapbird::Sanitizer::Stack->sanitize(\@large_number_stack);

is $sanitized_large_num_html, $expected_large_num_html, 'is stack properly handling very large start_time and end_time values?';

# Test contains undef entries
my @stack_with_undef = (
  {
    start_time => 100,
    end_time => 200,
    name => 'valid stack'
  },
  undef 
 );

my $expected_stack_with_undef_html = qq|<div class="slapbird-stack-row"><span class="slapbird-stack-row-name">valid_entry</span> - <span class="slapbird-stack-row-time">100.00</span>ms</div>|;
my $sanitized_stack_with_undef_html = Slapbird::Sanitizer::Stack->sanitize(\@stack_with_undef);

is $sanitized_stack_with_undef_html, $expected_stack_with_undef_html, 'is stack properly handdled when it contains undef entries?';

done_testing;

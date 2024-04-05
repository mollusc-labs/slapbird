package Slapbird::DTO::HTTPTransaction;

use Moo;

for (
    qw(type method end_point start_time end_time
    response_code response_size request_id request_size)
  )
{
    has $_ => (
        is      => 'rw',
        default => sub { undef; }
    );
}

1;

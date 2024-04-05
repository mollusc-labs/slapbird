package Slapbird::Sanitizer::HTTPTransaction;

# Slapbird  Copyright (C) 2024  Rawley Fowler, Mollusc Labs
# This program comes with ABSOLUTELY NO WARRANTY; for details type `show w'.
# This is free software, and you are welcome to redistribute it
# under certain conditions; type `show c' for details.

use strict;
use warnings;

use JSON::Validator;
use List::Util qw(any);
use DateTime;
use HTML::Escape qw(escape_html);
use namespace::clean;

sub sanitize {
  my ($class, $json) = @_;

  $json->{total_time}
    = sprintf('%.2f', $json->{end_time}) - ($json->{start_time});
  $json->{start_time} = sprintf('%.2f', $json->{start_time});
  $json->{end_time}   = sprintf('%.2f', $json->{end_time});

  if ($json->{stack}) {
    $json->{stack} = join(
      "\n",
      map {
            '<div class="slapbird-stack-row">'
          . '<span class="slapbird-stack-row-name">'
          . escape_html($_->{name})
          . '</span> - <span class="slapbird-stack-row-time">'
          . escape_html(sprintf('%.2f', $_->{end_time} - $_->{start_time}))
          . '</span>ms'
          . '</div>'
      } @{$json->{stack}}
    );
  }
  else {
    $json->{stack} = '';
  }

  if ($json->{error}) {
    $json->{error}
      = map { '<div class="slapbird-error-row">' . escape_html($_) . '</div>' }
      split(/\n/, $json->{error});
  }

  $json->{request_headers} = join("\n",
    map { $_ . ': ' . $json->{request_headers}->{$_} }
      keys(%{$json->{request_headers}}));
  $json->{response_headers} = join("\n",
    map { $_ . ': ' . $json->{response_headers}->{$_} }
      keys(%{$json->{response_headers}}));

  return $json;
}

1;

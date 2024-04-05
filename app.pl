#!/usr/bin/env perl

# Slapbird  Copyright (C) 2024  Rawley Fowler, Mollusc Labs
# This program comes with ABSOLUTELY NO WARRANTY; for details type `show w'.
# This is free software, and you are welcome to redistribute it
# under certain conditions; type `show c' for details.

use strict;
use warnings;

use Mojo::File qw(curfile);
use lib curfile->sibling('lib')->to_string();
use Mojolicious::Commands;
use Dotenv;

Dotenv->load();

Mojolicious::Commands->start_app('Slapbird');

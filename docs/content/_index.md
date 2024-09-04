+++
title = 'Getting Started'
date = 2024-08-19T17:08:34-06:00
draft = false
weight = 20
+++
## Getting Started
1. Login to [SlapbirdAPM](https://slapbirdapm.com) via Github
2. Create your application
3. Copy your API key

**Note: You will have to restart your application to see analytics.**

## Mojolicious

4. Install the SlapbirdAPM Mojolicious plugin ie. cpan -I SlapbirdAPM::Agent::Mojo
5. Add the plugin to your application with one line of code plugin 'SlapbirdAPM';
6. Add the SLAPBIRDAPM_API_KEY environment variable to your application\
   **Optionally:** You can also pass your API key to the plugin via plugin 'SlapbirdAPM', key => $API_KEY


## Dancer2

4. Install the SlapbirdAPM Dancer2 plugin ie. cpan -I SlapbirdAPM::Agent::Dancer2
5. Add the plugin to your Dancer2 application ie use Dancer2::Plugin::SlapbirdAPM
6. Add the SLAPBIRDAPM_API_KEY environment variable to your application\
   **Optionally:** You can also pass your API key to the plugin via config key => $API_KEY in your config.yml
   

## Plack

4. Install the SlapbirdAPM Plack middleware ie. cpan -I SlapbirdAPM::Agent::Plack
5. Add the middleware to your application, typically this is done using Plack::Builder
6. Add the SLAPBIRDAPM_API_KEY environment variable to your application\
   **Optionally:** You can also pass your API key to the plugin via key => $API_KEY in your Plack::Builder declaration


+++
title = 'Mojolicious'
date = 2024-08-19T17:08:34-06:00
draft = false
weight = 20
+++
## Getting Started with Mojolicious

1. Login to [SlapbirdAPM](https://slapbirdapm.com) via Github
2. Create your application
3. Copy your API key
4. Install the SlapbirdAPM Mojolicious plugin ie. cpan -I SlapbirdAPM::Agent::Mojo
5. Add the plugin to your application with one line of code plugin 'SlapbirdAPM';
6. Add the SLAPBIRDAPM_API_KEY environment variable to your application\
   **Optionally:** You can also pass your API key to the plugin via plugin 'SlapbirdAPM', key => $API_KEY

**You will have to restart your application to see analytics.**

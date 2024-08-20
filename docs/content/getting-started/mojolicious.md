+++
title = 'Mojolicious'
date = 2024-08-19T17:08:34-06:00
draft = false
+++
### Getting Started with Mojolicious

Please check out our examples on Github!
Before you see analytics you will have to restart your application.


1. Login to SlapbirdAPM via Github
2. Create your application
3. Copy your API key
4. Install the SlapbirdAPM Mojolicious plugin ie. cpan -I SlapbirdAPM::Agent::Mojo
5. Add the plugin to your application with one line of code plugin 'SlapbirdAPM';
6. Add the SLAPBIRDAPM_API_KEY environment variable to your application
   **Optionally:** You can also pass your API key to the plugin via plugin 'SlapbirdAPM', key => $API_KEY

# You will have to restart your application to see analytics.

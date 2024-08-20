+++
title = 'Plack'
date = 2024-08-19T17:08:34-06:00
draft = false
+++
### Getting Started with Plack

Please check out our examples on Github!
Before you see analytics you will have to restart your application.


1. Copy your API key
2. Install the SlapbirdAPM Plack middleware ie. cpan -I SlapbirdAPM::Agent::Plack
3. Add the middleware to your application, typically this is done using Plack::Builder
4. Add the SLAPBIRDAPM_API_KEY environment variable to your application
   **Optionally:** You can also pass your API key to the plugin via key => $API_KEY in your Plack::Builder declaration

# You will have to restart your application to see analytics.

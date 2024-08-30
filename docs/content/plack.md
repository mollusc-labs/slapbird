+++
title = 'Plack'
date = 2024-08-19T17:08:34-06:00
draft = false
weight = 40
+++
## Getting Started with Plack

1. Login to [SlapbirdAPM](https://slapbirdapm.com) via Github
2. Create your application
3. Copy your API key
4. Install the SlapbirdAPM Plack middleware ie. cpan -I SlapbirdAPM::Agent::Plack
5. Add the middleware to your application, typically this is done using Plack::Builder
6. Add the SLAPBIRDAPM_API_KEY environment variable to your application\
   **Optionally:** You can also pass your API key to the plugin via key => $API_KEY in your Plack::Builder declaration

**You will have to restart your application to see analytics.**

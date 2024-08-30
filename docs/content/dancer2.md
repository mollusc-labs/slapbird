+++
title = 'Dancer2'
date = 2024-08-27T17:08:34-06:00
draft = false
weight = 30
+++
## Dancer2

1. Login to [SlapbirdAPM](https://slapbirdapm.com) via Github
2. Create your application
3. Copy your API key
4. Install the SlapbirdAPM Dancer2 plugin ie. cpan -I SlapbirdAPM::Agent::Dancer2
5. Add the plugin to your Dancer2 application ie use Dancer2::Plugin::SlapbirdAPM
6. Add the SLAPBIRDAPM_API_KEY environment variable to your application\
   **Optionally:** You can also pass your API key to the plugin via config key => $API_KEY in your config.yml
   
**You will have to restart your application to see analytics**


+++
title = 'Arguments'
date = 2024-08-26T15:14:41-06:00
draft = false
weight = 50
+++

# Arguments
All arguments are passed as key => value pairs.

## Ignored Headers
Sets headers to be ignored in the header output.
{{< tabs "ign_args" >}}
{{< tab "Mojo" >}}
Pass the headers to be exluded as part of the plugin setup.
```
use Mojolicious::Lite -signatures;

plugin 'SlapbirdAPM',
    ignored_headers => ['Header'];
    
# Set up your endpoints

app->start;
```
{{< /tab >}}

{{< tab "Dancer2" >}}
Set the ignored_headers in your config.yaml.
```
plugins:
    SlapbirdAPM:
        ignore_headers:
            - 'Header'
```
{{< /tab >}}

{{< tab "Plack" >}}
Pass the headers to the SlapbirdAPM plugin as part of the builder declaration.
```
use Plack::Builder;

# Set up your endpoints

builder {
    enable 'SlapbirdAPM', ignored_headers => ['Header'];
    $app;
};
```
{{< /tab >}}
{{< /tabs >}}

## Key
**Setting the key is required to see analytics.**\
Login to [SlapbirdAPM](https://slapbirdapm.com) via Github.\
Copy your API key.\
Add the SLAPBIRDAPM_API_KEY environment variable to your application, or set it in your plugin configuration.
{{< tabs "key_args" >}}
{{< tab "Mojo" >}}
Pass the API key as part of the plugin setup.
```
use Mojolicious::Lite -signatures;

plugin 'SlapbirdAPM',
    key => 'your_slapbirdapm_api_key';
    
# Set up your endpoints

app->start;
```
{{< /tab >}}

{{< tab "Dancer2" >}}
Set the API key in your config.yaml.
```
plugins:
    SlapbirdAPM:
        key: 'your_slapbirdapm_api_key'
```
{{< /tab >}}

{{< tab "Plack" >}}
Pass the API key to the SlapbirdAPM plugin as part of the builder declaration.
```
use Plack::Builder;

# Set up your endpoints

builder {
    enable 'SlapbirdAPM', key => 'your_slapbird_api_key';
    $app;
};
```
{{< /tab >}}
{{< /tabs >}}

## Quiet
**quiet** hides all warnings. Disabled by default.
{{< tabs "quiet_args" >}}
{{< tab "Mojo" >}}
Enable or disable quiet mode as part of the plugin setup.
```
use Mojolicious::Lite -signatures;

plugin 'SlapbirdAPM',
    quiet => 1;
    
# Set up your endpoints

app->start;
```
{{< /tab >}}

{{< tab "Dancer2" >}}
Enable or disable quiet mode in your config.yaml.
```
plugins:
    SlapbirdAPM:
        quiet: 1 
```
{{< /tab >}}

{{< tab "Plack" >}}
Enable or disable quiet mode in the SlapbirdAPM plugin as part of the builder declaration.
```
use Plack::Builder;

# Set up your endpoints

builder {
    enable 'SlapbirdAPM', quiet => 1;
    $app;
};
```
{{< /tab >}}
{{< /tabs >}}

## Topology
Topology allows viewing dependencies of services. Enabled by default.
{{< tabs "top_args" >}}
{{< tab "Mojo" >}}
Enable or disable topology as part of the plugin setup.
```
use Mojolicious::Lite -signatures;

# disable topology
plugin 'SlapbirdAPM',
    topology => 0;
    
# Set up your endpoints

app->start;
```
{{< /tab >}}

{{< tab "Dancer2" >}}
Enable or disable topology in your config.yaml.
```
# disable topology
plugins:
    SlapbirdAPM:
        topology: 0
```
{{< /tab >}}

{{< tab "Plack" >}}
Enable or disable topology in the SlapbirdAPM plugin as part of the builder declaration.
```
use Plack::Builder;

# Set up your endpoints

# disable topology
builder {
    enable 'SlapbirdAPM', topology => 0;
    $app;
};
```
{{< /tab >}}
{{< /tabs >}}

## Trace
Trace enables or disables stacktraces per request. Enabled by default.\
*Disabling improves performance.*
{{< tabs "trace_args" >}}
{{< tab "Mojo" >}}
Enable or disable stacktraces as part of the plugin setup.
```
use Mojolicious::Lite -signatures;

# disable stacktrace
plugin 'SlapbirdAPM',
    trace => 0;
    
# Set up your endpoints

app->start;
```
{{< /tab >}}

{{< tab "Dancer2" >}}
Enable or disable stacktraces in your config.yaml.
```
# disable stacktraces
plugins:
    SlapbirdAPM:
        trace: 0
```
{{< /tab >}}

{{< tab "Plack" >}}
Enable or disable stacktraces in your SlapbirdAPM plugin as part of the builder declaration.
```
use Plack::Builder;

# Set up your endpoints

# disable stacktraces
builder {
    enable 'SlapbirdAPM', trace => 0;
    $app;
};
```
{{< /tab >}}
{{< /tabs >}}

## Trace Modules
Set modules to be be traced.
{{< tabs "traceM_args" >}}
{{< tab "Mojo" >}}
Pass the modules to be traced as part of the plugin setup.
```
use Mojolicious::Lite -signatures;

plugin 'SlapbirdAPM',
    trace_modules => ['My::Module'];
    
# Set up your endpoints

app->start;
```
{{< /tab >}}

{{< tab "Dancer2" >}}
Set the modules to be traced in your config.yaml.
```
plugins:
    SlapbirdAPM:
        trace_modules:
            - 'My::Module'
```
{{< /tab >}}

{{< tab "Plack" >}}
Pass the modules to be traced to the SlapbirdAPM plugin in your builder declaration.
```
use Plack::Builder;

# Set up your endpoints

builder {
    enable 'SlapbirdAPM', trace_modules => ['My::Module'];
    $app;
};
```
{{< /tab >}}
{{< /tabs >}}


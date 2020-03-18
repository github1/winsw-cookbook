# winsw-cookbook
This cookbook provides a custom Chef resource which configures Windows services using [kohsuke/winsw][winsw].

## Installation

If using [Berkshelf][berkshelf], add a dependency to this repo:
```
cookbook 'winsw', git: 'https://github.com/github1/winsw-cookbook'
```

## Usage

A basic `winsw` resource can be configured as follows:

```ruby
winsw 'my_winsw_service' do
  executable 'java'
  args %w(-jar C:\\SomeService.jar)
end
```

## Properties

The resource properties generally correspond with configuration options defined
in the WinSW XML Configuration File described [here](https://github.com/kohsuke/winsw/blob/master/doc/xmlConfigFile.md).

###`args`
An array of arguments to pass to the executable.
###`basedir`
The directory to write the service configuration to. Defaults to `:file_cache_path`.
###`enabled`
If set to `false`, the service will be installed but it
will not be started. If the service is started before the converge, it will be stopped.
###`env_variables`
A hash of key value pairs which are set as environment variables to the service
process.
###`executable`
The path to the executable to run for the service.
###`extensions`
A array of extension configurations.
```ruby
winsw 'my_winsw_service' do
  executable 'java'
  args %w(-jar C:\\SomeService.jar)
  extensions [{
               :@enabled => 'true',
               :@className => 'winsw.Plugins.RunawayProcessKiller.RunawayProcessKillerExtension',
               :@id => 'killOnStartup',
               :pidfile => '%BASE%\pid.txt',
               :stopTimeout => 5000,
               :stopParentFirst => false,
            }]
end
```
```xml
<service>
 ...
 <extensions>
  <extension enabled="true" className="winsw.Plugins.RunawayProcessKiller.RunawayProcessKillerExtension" id="killOnStartup">
   <pidfile>%BASE%\pid.txt</pidfile>
   <stopTimeout>5000</stopTimeout>
   <stopParentFirst>false</stopParentFirst>
  </extension>
 </extensions>
</service>
```
###`log_mode`
Sets the `logmode` configuration option.
###`options`
A hash of values to set in the configuration. These may override any of the 
properties which are set directly on the resource. The hash is translated into XML. 
Regular hash keys are translated directly into <tag> elements and keys prefixed 
with `@` are treated as attributes.
```ruby
winsw 'my_winsw_service' do
  executable 'java'
  args %w(-jar C:\\SomeService.jar)
  options :log => {
    :@mode => 'rotate'
  }
end
```
```xml
<service>
 <executable>java</executable>
 <arguments>-jar C:\\SomeService.jar</arguments>
 <log mode="rotate"/>
</service>
```
###`service_description`
The description used when registering the Windows service. Defaults to `windows_serviceName`.
###`service_name`
The name of the service.
###`startargs`
An array of arguments to pass when starting the service.
###`startmode`
The windows service start mode / startup type - e.g. (Automatic, Manual, Disabled)
###`stopargs`
An array of arguments to pass when stopping the service.
###`stopexecutable`
The path to the executable to run for stopping the service (optional).
###`supported_runtimes`
An array of .NET runtime versions which are set in the [WinSW EXE Configuration File](https://github.com/kohsuke/winsw/blob/master/doc/exeConfigFile.md).
###`windows_service_name`
The name used when registering the Windows service (i.e. the name of the service displayed in services.msc). Defaults to `$#{new_resource.name || new_resource.service_name}`.
###`winsw_bin_url`
The url for `winsw.exe` to download.

## Contribute

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

[LICENSE](LICENSE)

[github1]:      https://github.com/github1
[repo]:         https://github.com/github1/winsw-cookbook
[issues]:       https://github.com/github1/winsw-cookbook/issues
[winsw]:        https://github.com/kohsuke/winsw
[berkshelf]:    https://docs.chef.io/berkshelf.html

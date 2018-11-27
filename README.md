# winsw-cookbook
This cookbook provides a Chef resource which configures Windows services using [kohsuke/winsw][winsw].

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
  args [ '-jar', 'C:\\SomeService.jar' ]
end
```

## Attributes

The resource attributes generally correspond with configuration options defined
in the WinSW XML Configuration File described [here](https://github.com/kohsuke/winsw/blob/master/doc/xmlConfigFile.md).

### windows_service_name
The name used when registering the Windows service. Defaults to `$#{name}`.

### service_description

The description used when registering the Windows service. Defaults to `windows_serviceName`.

### enabled

If set to `false`, the service wrapper configuration will be written, but it
will not be started. If the service is started during a converge, setting this
to `false` will cause the service to be stopped.

### basedir

The directory to write the service configuration to. Defaults to `:file_cache_path`.

### executable

The path to the executable to run for the service.

### args

An array of arguments to pass to the executable.

### env_variables

A hash of key value pairs which are set as environment variables to the service
process.

### log_mode

Sets the `logmode` configuration option.

### options

A hash of values to set in the configuration. These may override any of the
above attributes. The hash is translated into XML. Regular keys are translated
directly into <tag> elements and keys prefixed with `@` are treated as attributes.

#### Example

```ruby
winsw 'my_winsw_service' do
  executable 'java'
  args [ '-jar', 'C:\\SomeService.jar' ]
  options :log => {
    :@mode => 'rotate'
  }
end
```

Outputs:

```xml
<service>
 ...
 <log mode="rotate"/>
</service>
```

### extensions

An array of extensions to add to the configuration.

#### Example

```ruby
winsw 'my_winsw_service' do
  executable 'java'
  args [ '-jar', 'C:\\SomeService.jar' ]
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

Outputs:

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

### supported_runtimes

An array of .NET runtime versions which are set in the [WinSW EXE Configuration File](https://github.com/kohsuke/winsw/blob/master/doc/exeConfigFile.md).

### winsw_bin_url

The download URL for WinSW to use. Defaults to [winsw-v2.1.2](https://github.com/kohsuke/winsw/releases/download/winsw-v2.1.2/WinSW.NET4.exe).

## Development

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

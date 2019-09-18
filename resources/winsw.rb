class Chef
  class Resource::WinSW < Resource

    resource_name :winsw

    default_action :install

    property :service_name, String
    property :windows_service_name, String
    property :service_description, String
    property :service_exec, String
    property :service_descriptor_xml_path, String
    property :enabled, [TrueClass, FalseClass], default: true
    property :basedir, String
    property :executable, String, required: true
    property :args, Array, default: []
    property :env_variables, Hash, default: {}
    property :log_mode, String, default: 'rotate'
    property :options, Hash, default: {}
    property :extensions, Array, default: []
    property :supported_runtimes, Array, default: %w( v4.0 v2.0.50727 )
    property :winsw_bin_url, String, default: 'https://github.com/kohsuke/winsw/releases/download/winsw-v2.1.2/WinSW.NET4.exe'

    def after_created
      service_name = instance_variable_get(:@service_name) || instance_variable_get(:@name)
      instance_variable_set(:@service_name, service_name)

      windows_service_name = instance_variable_get(:@windows_service_name) || "$#{service_name}"
      instance_variable_set(:@windows_service_name, windows_service_name)

      service_description = instance_variable_get(:@service_description) || windows_service_name
      instance_variable_set(:@service_description, service_description)

      basedir = ::File.join((instance_variable_get(:@basedir) || "Config[:file_cache_path]}/#{service_name}"), service_name)
      instance_variable_set(:@basedir, basedir)
      instance_variable_set(:@service_exec, "#{basedir}/#{service_name}.exe".gsub('/', '\\'))

      instance_variable_set(:@service_descriptor_xml_path, ::File.join(basedir, "#{service_name}.xml").gsub('/', '\\'))
    end

    action :install do

      extend ::WinSW::ResourceHelper

      configuration_sets = {}
      configuration_sets["#{new_resource.service_name}_test"] = {
          :service_name => "#{new_resource.service_name}_test",
          :windows_service_name => "#{new_resource.service_name}_test",
          :service_base => "#{new_resource.basedir}/test".gsub('/', '\\'),
          :service_exec => "#{new_resource.basedir}/test/test.exe".gsub('/', '\\'),
          :service_descriptor_xml_path => "#{new_resource.basedir}/test/test.xml".gsub('/', '\\'),
          :supported_runtime_config => ::File.join(new_resource.basedir, 'test/test.exe.config'),
          :executable => 'whoami',
          :test => true
      }
      configuration_sets[new_resource.service_name] = {
          :service_name => new_resource.service_name,
          :windows_service_name => new_resource.windows_service_name,
          :service_base => new_resource.basedir,
          :service_exec => new_resource.service_exec,
          :service_descriptor_xml_path => new_resource.service_descriptor_xml_path,
          :executable => new_resource.executable,
          :supported_runtime_config => ::File.join(new_resource.basedir, "#{new_resource.service_name}.exe.config"),
          :test => false
      }

      powershell_script "#{new_resource.name} install .Net framework version 3.5" do
        code 'Install-WindowsFeature Net-Framework-Core'
        only_if {
          new_resource.supported_runtimes.empty? || (new_resource.supported_runtimes.size == 1 && new_resource.supported_runtimes.include?('v2.0.50727'))
        }
      end

      configuration_sets.each do |key, config|

        directory config[:service_base] do
          recursive true
          action :create
        end

        if new_resource.supported_runtimes.empty?
          file config[:supported_runtime_config] do
            action :delete
          end
        else
          template config[:supported_runtime_config] do
            cookbook 'winsw'
            source 'winsw.exe.config.erb'
            variables({
                          :supported_runtimes => new_resource.supported_runtimes
                      })
          end
        end

        winsw_download_path = "#{Config[:file_cache_path]}\\#{::File.basename(new_resource.winsw_bin_url)}"
        remote_file "#{key} download winsw" do
          source new_resource.winsw_bin_url
          path ::File.join(Config[:file_cache_path], ::File.basename(new_resource.winsw_bin_url))
        end

        execute "#{key} update executable" do
          command "net stop \"#{config[:windows_service_name]}\" & Ver > nul & copy /B /Y #{winsw_download_path} #{config[:service_exec]}"
          not_if "fc /B #{winsw_download_path} #{config[:service_exec]}"
          notifies :run, "execute[#{key} restart re-configured service]", :immediately if new_resource.enabled && !config[:test]
        end

        file config[:service_descriptor_xml_path] do
          content prepare_config_xml(
                      config[:windows_service_name],
                      new_resource.service_description,
                      new_resource.env_variables,
                      config[:executable],
                      new_resource.args,
                      new_resource.log_mode,
                      new_resource.options,
                      new_resource.extensions,
                      config[:test])
          notifies :run, "execute[#{key} restart re-configured service]", :immediately if new_resource.enabled && !config[:test]
        end

        if config[:test]
          file "#{config[:service_exec]}.bat" do
            content %Q[@echo off
#{config[:service_exec]} test
if errorlevel 1 (
  exit /b 0
)]
          end
        else
          execute "#{key} install" do
            command "#{config[:service_exec]} install"
            only_if status_is(config[:service_exec], :non_existent)
          end

          restart_resource = build_restart_resource "#{key} restart re-configured service"
          restart_resource.action :nothing
          restart_resource.only_if { new_resource.enabled }

          start_resource = build_start_resource "#{key} start enabled service"
          start_resource.only_if { new_resource.enabled }

          stop_resource = build_stop_resource "#{key} stop disabled service"
          stop_resource.not_if { new_resource.enabled }
        end

      end

    end

    action :start do
      extend ::WinSW::ResourceHelper
      build_start_resource "#{new_resource.name} start"
    end

    action :stop do
      extend ::WinSW::ResourceHelper
      build_stop_resource "#{new_resource.name} stop"
    end

    action :restart do
      extend ::WinSW::ResourceHelper
      build_restart_resource "#{new_resource.name} restart"
    end

    action :uninstall do
      extend ::WinSW::ResourceHelper
      service_exec = new_resource.service_exec
      build_stop_resource "#{new_resource.name} stop"
      execute "#{new_resource.name} uninstall" do
        command "#{service_exec} uninstall"
        not_if status_is(service_exec, :non_existent)
      end
    end

    action :test do
      extend ::WinSW::ResourceHelper
      service_exec = new_resource.service_exec
      build_stop_resource "#{new_resource.name} stop"
      execute "#{new_resource.name} test configuration" do
        command "#{service_exec} test"
        not_if status_is(service_exec, :non_existent)
      end
    end
  end
end
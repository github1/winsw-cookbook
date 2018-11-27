class Chef
  class Resource::WinSW < Resource

    resource_name :winsw

    default_action :install

    property :service_name, String
    property :windows_service_name, String
    property :service_description, String
    property :service_exec, String
    property :enabled, [TrueClass, FalseClass], default: true
    property :basedir, String
    property :executable, String, required: true
    property :args, Array, default: []
    property :env_variables, Hash, default: {}
    property :log_mode, String, default: 'rotate'
    property :options, Hash, default: {}
    property :extensions, Array, default: []
    property :supported_runtimes, Array, default: %w( v2.0.50727 v4.0 )
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
    end

    action :install do
      extend ::WinSW::ResourceHelper

      service_name = new_resource.service_name
      windows_service_name = new_resource.windows_service_name
      service_base = new_resource.basedir
      service_exec = new_resource.service_exec

      directory service_base do
        recursive true
        action :create
      end

      powershell_script "#{new_resource.name} install .Net framework version 3.5" do
        code 'Install-WindowsFeature Net-Framework-Core'
        only_if {
          new_resource.supported_runtimes.empty? || (new_resource.supported_runtimes.size == 1 && new_resource.supported_runtimes.include?('v2.0.50727'))
        }
      end

      supported_runtime_config = ::File.join(service_base, "#{service_name}.exe.config")
      if new_resource.supported_runtimes.empty?
        file supported_runtime_config do
          action :delete
        end
      else
        template supported_runtime_config do
          cookbook 'winsw'
          source 'winsw.exe.config.erb'
          variables({
                        :supported_runtimes => new_resource.supported_runtimes
                    })
        end
      end

      winsw_download_path = "#{Config[:file_cache_path]}\\#{::File.basename(new_resource.winsw_bin_url)}"
      remote_file "#{new_resource.name} download winsw" do
        source new_resource.winsw_bin_url
        path ::File.join(Config[:file_cache_path], ::File.basename(new_resource.winsw_bin_url))
      end

      execute "#{new_resource.name} update executable" do
        command "net stop \"#{windows_service_name}\" & Ver > nul & copy /B /Y #{winsw_download_path} #{service_exec}"
        not_if "fc /B #{winsw_download_path} #{service_exec}"
        notifies :run, "execute[#{new_resource.name} restart re-configured service]", :immediately if new_resource.enabled
      end

      file ::File.join(service_base, "#{service_name}.entrypoint.bat") do
        content %Q[@echo off
if "%WINSW_SVC_EXECUTABLE%"=="" (
goto setentrypoint
)
goto :run
:setentrypoint
set "WINSW_SVC_EXECUTABLE=#{new_resource.executable}"
:run
echo Running %WINSW_SVC_EXECUTABLE%
%WINSW_SVC_EXECUTABLE% %*]
        notifies :run, "execute[#{new_resource.name} restart re-configured service]", :immediately if new_resource.enabled
      end

      file ::File.join(service_base, "#{service_name}.xml") do
        content prepare_config_xml(
                    windows_service_name,
                    new_resource.service_description,
                    new_resource.env_variables,
                    "%BASE%\\#{service_name}.entrypoint.bat",
                    new_resource.args,
                    new_resource.log_mode,
                    new_resource.options,
                    new_resource.extensions)
        notifies :run, "execute[#{new_resource.name} restart re-configured service]", :immediately if new_resource.enabled
      end

      execute "#{new_resource.name} install" do
        command "#{service_exec} install"
        only_if status_is(service_exec, :non_existent)
      end

      restart_resource = build_restart_resource "#{new_resource.name} restart re-configured service"
      restart_resource.action :nothing
      restart_resource.only_if { new_resource.enabled }

      start_resource = build_start_resource "#{new_resource.name} start enabled service"
      start_resource.only_if { new_resource.enabled }

      stop_resource = build_stop_resource "#{new_resource.name} stop disabled service"
      stop_resource.not_if { new_resource.enabled }

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

  end
end
class Chef
  class Resource::WinSW < Resource

    resource_name :winsw

    default_action :install

    property :name, kind_of: String, name_attribute: true
    property :service_name, kind_of: String
    property :on_install, kind_of: Symbol, default: :start
    property :basedir, kind_of: String
    property :executable, kind_of: String, required: true
    property :args, kind_of: Array, default: []
    property :env_variables, kind_of: Hash, default: {}
    property :options, kind_of: Hash, default: {}
    property :supported_runtimes, kind_of: Array, default: %w( v2.0.50727 v4.0 )

    action :install do

      service_name = new_resource.service_name || new_resource.name
      service_base = "#{new_resource.basedir || Config[:file_cache_path]}/#{service_name}"
      service_exec = "#{service_base}/#{service_name}.exe".gsub('/', '\\')

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

      remote_file "#{new_resource.name} download winsw" do
        source 'http://repo.jenkins-ci.org/releases/com/sun/winsw/winsw/1.18/winsw-1.18-bin.exe'
        path service_exec
        action :create_if_missing
      end

      template ::File.join(service_base, "#{service_name}.xml") do
        cookbook 'winsw'
        source 'winsw.xml.erb'
        variables({
                      :service_name => "$#{service_name}",
                      :executable => new_resource.executable,
                      :arguments => new_resource.args,
                      :env_vars => new_resource.env_variables,
                      :options => new_resource.options
                  })
        notifies :run, "execute[#{new_resource.name} restart]", :immediately
      end

      execute "#{new_resource.name} restart" do
        action :nothing
        command "#{service_exec} restart"
        not_if { new_resource.on_install == :stop }
        not_if "#{service_exec} status | find /i \"NonExistent\""
      end

      execute "#{new_resource.name} install" do
        command "#{service_exec} install"
        only_if "#{service_exec} status | find /i \"NonExistent\""
      end

      execute "#{new_resource.name} start" do
        command "#{service_exec} start"
        not_if { new_resource.on_install == :stop }
        only_if "#{service_exec} status | find /i \"Stopped\""
      end

      execute "#{new_resource.name} stop" do
        command "#{service_exec} stop"
        not_if { new_resource.on_install == :start }
        only_if "#{service_exec} status | find /i \"Started\""
      end

    end

    action :start do
      execute "#{new_resource.name} start" do
        command "#{service_exec} start"
        only_if "#{service_exec} status | find /i \"Stopped\""
      end
    end

    action :stop do
      execute "#{new_resource.name} stop" do
        command "#{service_exec} stop"
        only_if "#{service_exec} status | find /i \"Started\""
      end
    end

    action :restart do

      service_name = new_resource.service_name || new_resource.name
      service_base = "#{new_resource.basedir || Config[:file_cache_path]}/#{service_name}"
      service_exec = "#{service_base}/#{service_name}.exe".gsub('/', '\\')

      execute "#{new_resource.name} restart" do
        command "#{service_exec} restart"
        not_if "#{service_exec} status | find /i \"NonExistent\""
      end

    end

    action :uninstall do

      service_name = new_resource.service_name || new_resource.name
      service_base = "#{new_resource.basedir || Config[:file_cache_path]}/#{service_name}"
      service_exec = "#{service_base}/#{service_name}.exe".gsub('/', '\\')

      execute "#{new_resource.name} stop" do
        command "#{service_exec} stop"
        not_if "#{service_exec} status | find /i \"NonExistent\""
        not_if "#{service_exec} status | find /i \"Stopped\""
      end

      execute "#{new_resource.name} uninstall" do
        command "#{service_exec} uninstall"
        not_if "#{service_exec} status | find /i \"NonExistent\""
      end

    end

  end
end
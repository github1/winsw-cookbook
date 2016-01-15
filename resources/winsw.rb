class Chef
  class Resource::WinSW < Resource

    resource_name :winsw

    default_action :install

    property :name, kind_of: String, name_attribute: true
    property :service_name, kind_of: String
    property :basedir, kind_of: String
    property :executable, kind_of: String, required: true
    property :args, kind_of: Array, default: []
    property :env_variables, kind_of: Hash, default: {}

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
      end

      remote_file "#{new_resource.name} download winsw" do
        source 'http://repo.jenkins-ci.org/releases/com/sun/winsw/winsw/1.16/winsw-1.16-bin.exe'
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
                      :env_vars => new_resource.env_variables
                  })
        notifies :run, "execute[#{new_resource.name} restart]", :immediately
      end

      execute "#{new_resource.name} restart" do
        action :nothing
        command "#{service_exec} restart"
        not_if "#{service_exec} status | find /i \"NonExistent\""
      end

      execute "#{new_resource.name} install" do
        command "#{service_exec} install"
        only_if "#{service_exec} status | find /i \"NonExistent\""
      end

      execute "#{new_resource.name} start" do
        command "#{service_exec} start"
        only_if "#{service_exec} status | find /i \"Stopped\""
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

      execute "#{new_resource.name} uninstall" do
        command "#{service_exec} uninstall"
        not_if "#{service_exec} status | find /i \"NonExistent\""
      end

    end

  end
end
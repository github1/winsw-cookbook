class Chef
  class Resource::WinSW < Resource::LWRPBase
    identity_attr :name
    provides :winsw
    self.resource_name = :winsw
    actions :install
    default_action :install
    attribute :name,
      kind_of: String,
      name_attribute: true
    attribute :basedir,
      kind_of: String,
      default: lazy { |r| Chef::Config[:file_cache_path] }
    attribute :executable,
      kind_of: String,
      required: true
    attribute :args,
      kind_of: Array,
      default: []
    attribute :env_variables,
      kind_of: Hash,
      default: {}
  end
end

class Chef
  class Provider::WinSW < Provider::LWRPBase
    use_inline_resources
    
    def whyrun_supported?
      true
    end
    
    action(:install) do

      service_name = "$#{new_resource.name}"
      service_base = "#{new_resource.basedir}/#{new_resource.name}"
      service_exec = "#{service_base}/#{new_resource.name}.exe"

      powershell_script "#{new_resource} install .Net framework version 3.5" do
        code "Install-WindowsFeature Net-Framework-Core"
      end

      directory service_base do
        recursive true
        action :create
      end

      remote_file "#{new_resource.name} download winsw" do
        source "http://repo.jenkins-ci.org/releases/com/sun/winsw/winsw/1.16/winsw-1.16-bin.exe"
        name service_exec
      end

      template ::File.join(service_base,"#{new_resource.name}.xml") do
        source "winsw.xml.erb"
        variables({
          :service_name => service_name,
          :executable => new_resource.executable,
          :arguments => new_resource.args,
          :env_vars => new_resource.env_variables
        })
        notifies :run, "execute[#{new_resource} restart]", :immediately
      end

      execute "#{new_resource} restart" do
        action :nothing
        command "#{service_exec} restart"
        not_if "#{service_exec} status | find \"NonExistent\""
      end

      execute "#{new_resource} install" do
        command "#{service_exec} install"
        only_if "#{service_exec} status | find \"NonExistent\""
      end

      execute "#{new_resource} start" do
        command "#{service_exec} start"
        only_if "#{service_exec} status | find \"Stopped\""
      end

    end
  
  end
end

Chef::Platform.set(
  resource: :winsw,
  provider: Chef::Provider::WinSW
)
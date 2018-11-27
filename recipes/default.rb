node['winsw']['service'].each do |service_name, service_info|
  winsw service_name do
    service_name service_info['service_name']
    service_description service_info['service_description']
    windows_service_name service_info['windows_service_name']
    action service_info['action']
    basedir service_info['basedir']
    enabled service_info['enabled']
    executable service_info['executable']
    args service_info['args']
    env_variables service_info['env_variables']
    options service_info['options']
    extensions service_info['extensions']
    supported_runtimes service_info['supported_runtimes']
    winsw_bin_url service_info['winsw_bin_url']
  end
end
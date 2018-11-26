node['winsw']['service'].each do |service_name, service_info|
  winsw service_name do
    action service_info['action']
    basedir service_info['basedir']
    enabled service_info['enabled']
    executable service_info['executable']
    args service_info['args']
    env_variables service_info['env_variables']
    options service_info['options'] if service_info['options']
    supported_runtimes service_info['supported_runtimes']
  end
end
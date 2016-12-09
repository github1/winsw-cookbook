node['winsw']['service'].each do |service_name, service_info|
  winsw service_name do
    basedir service_info['basedir']
    executable service_info['executable']
    args service_info['args']
    env_variables service_info['env_variables']
    options service_info['options'] if service_info['options']
  end
end
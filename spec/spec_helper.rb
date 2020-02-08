require 'chefspec'
require_relative '../libraries/winsw_resource_helper.rb'

module WinSW
  module BaseSpec
    def base_spec(&block)
      ChefSpec::Runner.new(step_into: ['winsw'], log_level: :debug) do |node|
        setup_node node
        block.call node unless block.nil?
      end.converge('winsw::default')
    end

    def setup_node(node)
      node.default['winsw']['service']['test_service']['action'] = :install
      node.default['winsw']['service']['test_service']['basedir'] = '/winsw/services'
      node.default['winsw']['service']['test_service']['executable'] = 'test.exe'
      node.default['winsw']['service']['test_service']['args'] = %w(arg0 arg1)
      node.default['winsw']['service']['test_service']['env_variables']['env0'] = 'env0 val'
      node.default['winsw']['service']['test_service']['options']['stopparentprocessfirst'] = true
    end

    def the_service_exists(service_name, state = true)
      the_service_is(service_name, :non_existent, !state)
    end

    def the_service_does_not_exist(service_name)
      the_service_exists(service_name, false)
    end

    def the_service_is(service_name, status, state = true)
      allow_any_instance_of(::Chef::Resource).to receive(:status_is).and_return(false)
      allow_any_instance_of(::Chef::Resource).to receive(:status_is).with(Regexp.new(Regexp.escape(service_name)), status).and_return(state)
    end

    def the_service_is_not(service_name, status)
      the_service_is(service_name, status, false)
    end

    def the_winsw_binaries_match(service_name, result = true)
      stub_command("fc /B \\cachepath\\WinSW.NET4.exe \\winsw\\services\\#{service_name}\\#{service_name}.exe").and_return(result)
    end

    def the_winsw_service_descriptor_xml_is_missing(service_name)
      stub_command("dir \\winsw\\services\\#{service_name}\\#{service_name}.xml > nul 2>&1").and_return(false)
    end

    def with_existing_config(h)
      allow_any_instance_of(::Chef::Resource).to receive(:parse_service_xml_from_file).and_return(h)
    end
  end
end

RSpec.configure do |config|
  config.include WinSW::BaseSpec
  config.platform = 'windows'
  config.version = '2012R2'
  config.file_cache_path = '\\cachepath'
end
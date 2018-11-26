require 'chefspec'

module WinSW
  module BaseSpec
    def base_spec(&block)
      ChefSpec::Runner.new(step_into: ['winsw'], log_level: :debug) do |node|
        setup_node node
        block.call node unless block.nil?
      end.converge('winsw::_winsw_spec_fixture')
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
      status_text = case status
                      when :non_existent then
                        'NonExistent'
                      when :stopped then
                        'Stopped'
                      when :started then
                        'Started'
                    end
      stub_command(/\.exe status \|/).and_return(false)
      stub_command("\\winsw\\services\\#{service_name}\\#{service_name}.exe status | %systemroot%\\system32\\find.exe /i \"#{status_text}\"").and_return(state)
    end

    def the_service_is_not(service_name, status)
      the_service_is(service_name, status, false)
    end

    def the_winsw_binaries_match(service_name, result = true)
      stub_command("fc /B \\cachepath\\winsw-1.18-bin.exe \\winsw\\services\\#{service_name}\\#{service_name}.exe").and_return(result)
    end
  end
end

RSpec.configure do |config|
  config.include WinSW::BaseSpec
  config.platform = 'windows'
  config.version = '2012R2'
  config.file_cache_path = '\\cachepath'
end
require_relative 'spec_helper.rb'

describe 'winsw resource' do

  def base_spec(&block)
    ChefSpec::SoloRunner.new(step_into: ['winsw'], log_level: :debug) do |node|
      setup_node node
      block.call node unless block.nil?
    end.converge('winsw::_winsw_spec_fixture')
  end

  def setup_node(node)
    node.default['winsw']['service']['test_service']['action'] = :install
    node.default['winsw']['service']['test_service']['basedir'] = '/winsw/services'
    node.default['winsw']['service']['test_service']['executable'] = 'test.exe'
    node.default['winsw']['service']['test_service']['args'] = ['arg0', 'arg1']
    node.default['winsw']['service']['test_service']['env_variables']['env0'] = 'env0 val'
    node.default['winsw']['service']['test_service']['options']['stopparentprocessfirst'] = true
  end

  def the_service_exists(service_name, state = true)
    the_service_is(service_name, :non_existant, !state)
  end

  def the_service_does_not_exist(service_name)
    the_service_exists(service_name, false)
  end

  def the_service_is(service_name, status, state = true)
    status_text = case status
                    when :non_existant then
                      'NonExistent'
                    when :stopped then
                      'Stopped'
                    when :running then
                      'Started'
                  end
    stub_command("\\winsw\\services\\#{service_name}\\#{service_name}.exe status | %systemroot%\\system32\\find.exe /i \"#{status_text}\"").and_return(state)
  end

  def the_service_is_not(service_name, status)
    the_service_is(service_name, status, false)
  end

  before do
    stub_command(/.*/).and_return(true)
  end

  describe 'when installed already' do
    let(:chef_run) do
      base_spec do |node|
        node.default['winsw']['service']['test_service']['enabled'] = false
      end
    end

    before do
      the_service_exists('test_service');
    end

    it 'is not installed again' do
      expect(chef_run).not_to run_execute('test_service install')
    end

  end

  describe 'when not installed yet' do
    let(:chef_run) do
      base_spec
    end

    before do
      the_service_does_not_exist('test_service')
      the_service_is('test_service', :stopped)
    end

    it 'downloads winsw' do
      expect(chef_run).to create_remote_file_if_missing('test_service download winsw')
    end

    it 'renders the winsw config file' do
      expect(chef_run).to create_template('/winsw/services/test_service/test_service.xml')
      expect(chef_run).to render_file('/winsw/services/test_service/test_service.xml').with_content(<<-EOT.strip)
<service>
  <id>$test_service</id>
  <name>$test_service</name>
  <description>$test_service</description>
  <env name="env0" value="env0 val"/>
  <executable>test.exe</executable>
  <arguments>arg0 arg1</arguments>
  <logmode>rotate</logmode>
  <stopparentprocessfirst>true</stopparentprocessfirst>
</service>
      EOT
    end

    it 'starts the service' do
      expect(chef_run).to run_execute('test_service install')
      expect(chef_run).to run_execute('test_service start')
    end

  end

  describe 'when disabled' do
    describe 'when already started' do
      let(:chef_run) do
        base_spec do |node|
          node.default['winsw']['service']['test_service']['enabled'] = false
        end
      end

      before do
        the_service_exists('test_service')
        the_service_is_not('test_service', :stopped)
        the_service_is('test_service', :running)
      end

      it 'updates the config' do
        expect(chef_run).to render_file('/winsw/services/test_service/test_service.xml')
      end

      it 'it stops the service' do
        expect(chef_run).to run_execute('test_service stop')
        expect(chef_run).not_to run_execute('test_service start')
      end
    end
    describe 'when already stopped' do
      let(:chef_run) do
        base_spec do |node|
          node.default['winsw']['service']['test_service']['enabled'] = false
        end
      end

      before do
        the_service_does_not_exist('test_service')
        the_service_is('test_service', :stopped)
        the_service_is_not('test_service', :running)
      end

      it 'updates the config' do
        expect(chef_run).to render_file('/winsw/services/test_service/test_service.xml')
      end

      it 'it does not explicitly stop the service' do
        expect(chef_run).not_to run_execute('test_service stop')
        expect(chef_run).not_to run_execute('test_service start')
      end
    end
  end

end
require_relative 'spec_helper.rb'

describe 'winsw::_winsw_spec_fixture' do
  let(:chef_run) do
    ChefSpec::SoloRunner.new(step_into: ['winsw'], log_level: :debug) do |node|
      node.set['winsw']['service']['test_service']['basedir'] = '/winsw/services'
      node.set['winsw']['service']['test_service']['executable'] = 'test.exe'
      node.set['winsw']['service']['test_service']['args'] = ['arg0', 'arg1']
      node.set['winsw']['service']['test_service']['env_variables']['env0'] = 'env0 val'
      node.set['winsw']['service']['test_service']['options']['stopparentprocessfirst'] = true
    end.converge(described_recipe)
  end

  before do
    stub_command("\\winsw\\services\\test_service\\test_service.exe status | find /i \"NonExistent\"").and_return(0)
    stub_command("\\winsw\\services\\test_service\\test_service.exe status | find /i \"Stopped\"").and_return(1)
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
    expect(chef_run).to run_execute('test_service install')
    expect(chef_run).to run_execute('test_service start')
  end

end
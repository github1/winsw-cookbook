require_relative 'spec_helper.rb'

describe 'winsw resource' do

  before do
    stub_command(/.*/).and_return(true)
    the_winsw_service_descriptor_xml_is_missing(false)
  end

  describe 'install action' do
    describe 'service is not disabled' do
      describe 'service not yet installed' do
        let(:chef_run) do
          base_spec
        end
        before do
          the_service_does_not_exist('test_service')
          the_winsw_binaries_match('test_service', false)
        end
        it 'downloads winsw' do
          expect(chef_run).to create_remote_file('test_service download winsw')
        end
        it 'updates the winsw executable' do
          puts chef_run
          expect(chef_run).to create_link('\winsw\services\test_service\test_service.exe')
          expect(chef_run.link('\winsw\services\test_service\test_service.exe'))
              .to notify('execute[test_service stop re-configured service]')
                      .to(:run).before
        end
        it 'renders the winsw config file' do
          expect(chef_run).to create_file('\\winsw\\services\\test_service\\test_service.xml')
          expect(chef_run).to render_file('\\winsw\\services\\test_service\\test_service.xml').with_content(<<-EOT.strip)
<service>
 <id>test_service</id>
 <name>test_service</name>
 <description>test_service</description>
 <executable>test.exe</executable>
 <arguments>arg0 arg1</arguments>
 <env name="env0" value="env0 val"/>
 <stopparentprocessfirst>true</stopparentprocessfirst>
 <logmode>rotate</logmode>
</service>
          EOT
          expect(chef_run.file('\\winsw\\services\\test_service\\test_service.xml'))
              .to notify('execute[test_service restart re-configured service]')
                      .to(:run).immediately
        end
        it 'is installed' do
          expect(chef_run).to run_execute('test_service install')
        end
        it 'starts the service' do
          the_service_is('test_service', :stopped)
          expect(chef_run).to run_execute('test_service start enabled service')
        end
      end

      describe 'startargs' do
        describe 'if startargs are set' do
          let(:chef_run) do
            base_spec do |node|
              node.default['winsw']['service']['test_service']['start_args'] = %w( start1 start2 )
            end
          end
          it 'renders them' do
            expect(chef_run).to render_file('\\winsw\\services\\test_service\\test_service.xml').with_content(<<-EOT.strip)
<service>
 <id>test_service</id>
 <name>test_service</name>
 <description>test_service</description>
 <executable>test.exe</executable>
 <arguments>arg0 arg1</arguments>
 <env name="env0" value="env0 val"/>
 <stopparentprocessfirst>true</stopparentprocessfirst>
 <startargument>start1</startargument>
 <startargument>start2</startargument>
 <logmode>rotate</logmode>
</service>
            EOT
          end
        end
      end

      describe 'startmode' do
        describe 'if startmode is changed' do
          let(:chef_run) do
            base_spec do |node|
              node.default['winsw']['service']['test_service']['startmode'] = 'Manual'
            end
          end
          before do
            the_service_exists('test_service')
            the_service_is('test_service', :started)
            with_existing_config({
              :startmode => 'Automatic'
            })
          end
          it 're-installs the service' do
            expect(chef_run).to run_execute('test_service uninstall re-configured service')
          end
        end
      end

      describe 'service already installed' do
        let(:chef_run) do
          base_spec
        end
        before do
          the_service_exists('test_service')
          the_service_is('test_service', :started)
        end
        it 'is not installed again' do
          expect(chef_run).not_to run_execute('test_service install')
        end
      end

      describe '.Net 3.5 runtime enablement' do
        describe 'if v2.0.50727 is the only supported runtime and .NET build of winsw is used' do
          let(:chef_run) do
            base_spec do |node|
              node.default['winsw']['service']['test_service']['supported_runtimes'] = %w( v2.0.50727 )
              node.default['winsw']['service']['test_service']['winsw_bin_url'] = 'https://github.com/winsw/winsw/releases/download/v2.11.0/WinSW.NET2.exe'
            end
          end
          it 'enables .Net 3.5 runtime' do
            expect(chef_run).to run_powershell_script('test_service install .Net framework version 3.5')
          end
        end
      end
    end

    describe 'service is disabled' do
      let(:chef_run) do
        base_spec do |node|
          node.default['winsw']['service']['test_service']['enabled'] = false
        end
      end
      it 'can stop the disabled service on configuration changes' do
        expect(chef_run.file('\\winsw\\services\\test_service\\test_service.xml'))
            .not_to notify('execute[test_service restart re-configured service]')
                        .to(:run).immediately
      end
      it 'does not start the service' do
        expect(chef_run).not_to run_execute('test_service start enabled service')
      end
    end
  end

  describe 'uninstall action' do
    let(:chef_run) do
      base_spec do |node|
        node.default['winsw']['service']['test_service']['action'] = :uninstall
      end
    end
    describe 'service is installed' do
      before do
        the_service_exists('test_service')
      end
      it 'uninstalls the service' do
        expect(chef_run).to run_execute('test_service uninstall')
      end
    end
    describe 'service is started' do
      before do
        the_service_is('test_service', :started)
      end
      it 'stops the service' do
        expect(chef_run).to run_execute('test_service stop')
      end
      it 'uninstalls the service' do
        expect(chef_run).to run_execute('test_service uninstall')
      end
    end
    describe 'service is not installed' do
      before do
        the_service_does_not_exist('test_service')
      end
      it 'does not try to uninstall it' do
        expect(chef_run).not_to run_execute('test_service uninstall')
      end
    end
  end

  describe 'start action' do
    let(:chef_run) do
      base_spec do |node|
        node.default['winsw']['service']['test_service']['action'] = :start
      end
    end
    describe 'service is stopped' do
      before do
        the_service_is('test_service', :stopped)
      end
      it 'starts the service' do
        expect(chef_run).to run_execute('test_service start')
      end
    end
    describe 'service is already started' do
      before do
        the_service_is('test_service', :started)
      end
      it 'does not try to start it again' do
        expect(chef_run).not_to run_execute('test_service start')
      end
    end
  end

  describe 'stop action' do
    let(:chef_run) do
      base_spec do |node|
        node.default['winsw']['service']['test_service']['action'] = :stop
      end
    end
    describe 'service is started' do
      before do
        the_service_is('test_service', :started)
      end
      it 'stops the service' do
        expect(chef_run).to run_execute('test_service stop')
      end
    end
    describe 'service is stopped' do
      before do
        the_service_is('test_service', :stopped)
      end
      it 'does not try to stop it again' do
        expect(chef_run).not_to run_execute('test_service stop')
      end
    end
  end

  describe 'restart action' do
    let(:chef_run) do
      base_spec do |node|
        node.default['winsw']['service']['test_service']['action'] = :restart
      end
    end
    describe 'service is installed' do
      before do
        the_service_exists('test_service')
      end
      it 'restarts the service' do
        expect(chef_run).to run_execute('test_service restart')
      end
    end
    describe 'service is not configured' do
      before do
        the_winsw_service_descriptor_xml_is_missing('test_service')
        the_service_exists('test_service')
      end
      it 'does not try to restart it' do
        expect(chef_run).not_to run_execute('test_service restart')
      end
    end
    describe 'service is not installed' do
      before do
        the_service_does_not_exist('test_service')
      end
      it 'does not try to restart it' do
        expect(chef_run).not_to run_execute('test_service restart')
      end
    end
  end

end
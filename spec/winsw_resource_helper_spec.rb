require_relative '../libraries/winsw_resource_helper.rb'

describe 'WinSw::ResourceHelper' do
  let(:helper) do
    Class.new.extend(WinSW::ResourceHelper)
  end
  describe 'prepare_config_xml' do
    it 'renders minimal configs' do
      expect(helper.prepare_config_xml(
          'a_service',
          'a_service',
          {
              :FOO => 'bar',
              :BAZ => 'quux'
          },
          'java.exe',
          %w(Xmx 512m -Xms 128m -jar foo.jar),
          'rotate',
          {})).to eq(%q[<service>
 <id>a_service</id>
 <name>a_service</name>
 <description>a_service</description>
 <executable>java.exe</executable>
 <arguments>Xmx 512m -Xms 128m -jar foo.jar</arguments>
 <env name="FOO" value="bar"/>
 <env name="BAZ" value="quux"/>
 <logmode>rotate</logmode>
</service>])
    end
    it 'renders log config' do
      expect(helper.prepare_config_xml(
          'a_service',
          'a_service',
          {},
          'java.exe',
          %w(),
          'rotate',
          {
              :log => {
                  :@mode => 'roll-by-size',
                  :sizeThreshold => 1024,
                  :keepFiles => 8
              }
          })).to eq(%q[<service>
 <id>a_service</id>
 <name>a_service</name>
 <description>a_service</description>
 <executable>java.exe</executable>
 <log mode="roll-by-size">
  <sizeThreshold>1024</sizeThreshold>
  <keepFiles>8</keepFiles>
 </log>
</service>])
      expect(helper.prepare_config_xml(
          'a_service',
          'a_service',
          {},
          'java.exe',
          %w(),
          'rotate',
          {
              :log => {
                  :@mode => 'reset'
              }
          })).to eq(%q[<service>
 <id>a_service</id>
 <name>a_service</name>
 <description>a_service</description>
 <executable>java.exe</executable>
 <log mode="reset"/>
</service>])
    end
    it 'renders extensions' do
      expect(helper.prepare_config_xml(
          'a_service', 'a_service',
          {},
          'java.exe',
          %w(),
          'rotate',
          {},
          [{
              :@enabled => 'true',
              :@className => 'winsw.Plugins.RunawayProcessKiller.RunawayProcessKillerExtension',
              :@id => 'killOnStartup',
              :pidfile => '%BASE%\pid.txt',
              :stopTimeout => 5000,
              :stopParentFirst => false,
           }])).to eq(%q[<service>
 <id>a_service</id>
 <name>a_service</name>
 <description>a_service</description>
 <executable>java.exe</executable>
 <logmode>rotate</logmode>
 <extensions>
  <extension enabled="true" className="winsw.Plugins.RunawayProcessKiller.RunawayProcessKillerExtension" id="killOnStartup">
   <pidfile>%BASE%\pid.txt</pidfile>
   <stopTimeout>5000</stopTimeout>
   <stopParentFirst>false</stopParentFirst>
  </extension>
 </extensions>
</service>])
    end
  end
  describe 'hash_to_xml_s' do
    it 'converts a hash to xml' do
      expect(helper.hash_to_xml_s(:foo => 'bar')).to eq('<foo>bar</foo>')
      expect(helper.hash_to_xml_s(:foo => 'bar',
                                  :baz => {
                                      :qux => 'quuz'
                                  })).to eq(%q[<foo>bar</foo><baz>
 <qux>quuz</qux>
</baz>])
    end
    it 'renders empty hash as self closing tag' do
      expect(helper.hash_to_xml_s(:foo => {})).to eq('<foo/>')
    end
    it 'joins array values' do
      expect(helper.hash_to_xml_s(:foo => %w(a b c))).to eq('<foo>a b c</foo>')
    end
    it 'renders attributes' do
      expect(helper.hash_to_xml_s(:foo => {:@bar => 'baz'})).to eq('<foo bar="baz"/>')
    end
  end
end
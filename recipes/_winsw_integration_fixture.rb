# workaround for https://github.com/test-kitchen/busser/issues/25
# windows_package 'ruby' do
#   source 'https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-2.4.9-1/rubyinstaller-devkit-2.4.9-1-x64.exe'
# end

remote_file '/openjdk.zip' do
  source 'https://bitbucket.org/alexkasko/openjdk-unofficial-builds/downloads/openjdk-1.7.0-u60-unofficial-windows-i586-image.zip'
  action :create_if_missing
end

directory '/openjdk'

powershell_script 'extract openjdk' do
  code %Q[$shell = new-object -com shell.application
$zip = $shell.NameSpace("C:\\openjdk.zip")
foreach($item in $zip.items())
{
$shell.Namespace("C:\\openjdk").copyhere($item)
}]
  not_if { ::Dir.entries('/openjdk').size > 2 }
end

remote_file '/SimpleWebServer.jar' do
  source 'http://www.jibble.org/files/SimpleWebServer.jar'
  action :create_if_missing
end

winsw 'my_service' do
  basedir 'C:/service'
  executable 'C:\\openjdk\\openjdk-1.7.0-u60-unofficial-windows-i586-image\\bin\\java'
  args %w( -Xrs -jar C:\\SimpleWebServer.jar )
  options :log => {
      :@mode => 'reset'
  },
  :pidfile => '%BASE%\pid.txt',
  :stopTimeout => 5000,
  :stopParentProcessFirst => false
end
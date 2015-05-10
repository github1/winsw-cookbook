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
  args [ '-jar', 'C:\\SimpleWebServer.jar' ]
end
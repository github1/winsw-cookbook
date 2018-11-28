Vagrant.configure('2') do |config|
  config.vm.provision 'shell',
                      inline: %q[
Mount-DiskImage -ImagePath "C:\\Users\\vagrant\\VBoxGuestAdditions.iso"
cd D:\\
certutil -addstore -f "TrustedPublisher" .\cert\vbox-sha1.cer
certutil -addstore -f "TrustedPublisher" .\cert\vbox-sha256.cer
certutil -addstore -f "TrustedPublisher" .\cert\vbox-sha256-r3.cer
D:\\VBoxWindowsAdditions-amd64.exe /S /force
]
end
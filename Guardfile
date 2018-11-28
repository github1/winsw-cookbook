guard :rspec, :cmd => 'rspec' do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^(recipes|libraries|resources)/(.+)\.rb$}) { |m|
    path = "spec/#{m[2]}_spec.rb"
    ::File.exists?(path) ? path : 'spec/default_spec.rb'
  }
  watch('spec/spec_helper.rb')  { 'spec' }
end

guard 'foodcritic', :cookbook_paths => '.' do
  watch(%r{libraries/.+\.rb$})
  watch(%r{recipes/.+\.rb$})
  watch(%r{resources/.+\.rb$})
  watch(%r{templates/.+$})
  watch('metadata.rb')
end

guard 'rspec' do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^(recipes|libraries|resources)/(.+)\.rb$}) { |m|
    "spec/#{m[2]}_spec.rb"
  }
  watch('spec/spec_helper.rb')  { 'spec' }
end

guard 'foodcritic', :cookbook_paths => '.' do
  watch(%r{libraries/.+\.rb$})
  watch(%r{recipes/.+\.rb$})
  watch(%r{resources/.+\.rb$})
  watch(%r{spec/.+\.rb$})
  watch(%r{templates/.+$})
  watch('metadata.rb')
end

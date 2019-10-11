require 'spec_helper'

describe service('my_service') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end
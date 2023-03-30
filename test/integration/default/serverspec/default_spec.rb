require 'spec_helper'

describe service('my_service') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end

describe service('my_other_service') do
  it { should be_installed }
  it { should_not be_enabled }
  it { should_not be_running }
end
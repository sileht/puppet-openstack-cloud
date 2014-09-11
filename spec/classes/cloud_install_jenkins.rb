require 'spec_helper'

describe 'cloud::install::jenkins' do

  shared_examples_for 'jenkins' do

    it 'install jenkins' do
      should contain_class('jenkins')
    end

    it 'install jenkins_job_builder' do
      should contain_class('jenkins_job_builder')
    end

  end


  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    it_configures 'jenkins'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end
    it_configures 'jenkins'
  end
end

require 'spec_helper'

describe 'cloud::install::puppetmaster' do

  shared_examples_for 'puppetmaster' do

    let :params do
      { :puppetconf_path     => '/etc/puppet/puppet.conf',
        :main_configuration  => {},
        :agent_configuration => {
          'certname' => { 'setting' => 'certname', 'value' => 'foo.bar' }
        },
        :master_configuration => {
          'timeout'  => { 'setting' => 'timeout', 'value' => '0' }
        }}
    end

    it 'install hiera' do
      should contain_class('hiera')
    end

    it 'configure the puppetdb settings of puppetmaster' do
      should contain_class('puppetdb::master::config')
    end

    it 'configure the puppet master configuration file' do
      should contain_init_setting('certname').with(
        :setting => 'certname',
        :value   => 'foo.bar',
        :section => 'agent',
        :path    => '/etc/puppet/puppet.conf',
      )
      should contain_init_setting('timeout').with(
        :setting => 'timeout',
        :value   => '0',
        :section => 'master',
        :path    => '/etc/puppet/puppet.conf',
      )
    end

  end


  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    it_configures 'puppetmaster'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end
    it_configures 'puppetmaster'
  end
end

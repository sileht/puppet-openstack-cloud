#
# Copyright (C) 2014 eNovance SAS <licensing@enovance.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# Unit tests for cloud::compute class
#

require 'spec_helper'

describe 'cloud::compute' do

  shared_examples_for 'openstack compute' do

    let :params do
      {
        :availability_zone       => 'MyZone',
        :nova_db_host            => '10.0.0.1',
        :nova_db_user            => 'nova',
        :nova_db_password        => 'secrete',
        :rabbit_hosts            => ['10.0.0.1'],
        :rabbit_password         => 'secrete',
        :rabbit_use_ssl          => true,
        :kombu_ssl_ca_certs      => '/ssl/ca/certs',
        :kombu_ssl_certfile      => '/ssl/cert/file',
        :kombu_ssl_keyfile       => '/ssl/key/file',
        :kombu_ssl_version       => 'SSLv3',
        :ks_glance_internal_host => '10.0.0.1',
        :glance_api_port         => '9292',
        :verbose                 => true,
        :debug                   => true,
        :use_syslog              => true,
        :ssl                     => true,
        :ssl_cacert              => '/ssl/ca/cert',
        :ssl_cert                => '/ssl/cert',
        :ssl_key                 => '/ssl/key',
        :neutron_protocol        => 'http',
        :neutron_endpoint        => '10.0.0.1',
        :neutron_region_name     => 'MyRegion',
        :neutron_password        => 'secrete',
        :memcache_servers        => ['10.0.0.1','10.0.0.2'],
        :log_facility            => 'LOG_LOCAL0'
      }
    end

    it 'configure nova common' do
      should contain_class('nova').with(
        :verbose             => true,
        :debug               => true,
        :use_syslog          => true,
        :log_facility        => 'LOG_LOCAL0',
        :rabbit_userid       => 'nova',
        :rabbit_hosts        => ['10.0.0.1'],
        :rabbit_password     => 'secrete',
        :rabbit_virtual_host => '/',
        :rabbit_use_ssl      => true,
        :kombu_ssl_ca_certs  => '/ssl/ca/certs',
        :kombu_ssl_certfile  => '/ssl/cert/file',
        :kombu_ssl_keyfile   => '/ssl/key/file',
        :memcached_servers   => ['10.0.0.1','10.0.0.2'],
        :database_connection => 'mysql://nova:secrete@10.0.0.1/nova?charset=utf8',
        :glance_api_servers  => 'http://10.0.0.1:9292',
        :log_dir             => false,
        :use_ssl             => true,
        :ca_file             => '/ssl/ca/cert',
        :cert_file           => '/ssl/cert',
        :key_file            => '/ssl/key',
      )
      should contain_nova_config('DEFAULT/resume_guests_state_on_host_boot').with('value' => true)
      should contain_nova_config('DEFAULT/default_availability_zone').with('value' => 'MyZone')
      should contain_nova_config('DEFAULT/servicegroup_driver').with_value('mc')
      should contain_nova_config('DEFAULT/glance_num_retries').with_value('10')
    end

    it 'configure neutron on compute node' do
      should contain_class('nova::network::neutron').with(
        :neutron_admin_password => 'secrete',
        :neutron_admin_auth_url => 'http://10.0.0.1:35357/v2.0',
        :neutron_region_name    => 'MyRegion',
        :neutron_url            => 'http://10.0.0.1:9696'
      )
    end

    it 'checks if Nova DB is populated' do
      should contain_exec('nova_db_sync').with(
        :command => 'nova-manage db sync',
        :user    => 'nova',
        :path    => '/usr/bin',
        :unless  => '/usr/bin/mysql nova -h 10.0.0.1 -u nova -psecrete -e "show tables" | /bin/grep Tables'
      )
    end

  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    it_configures 'openstack compute'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end
    it_configures 'openstack compute'
  end

end

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
# Unit tests for cloud::storage::rbd::osd class
#

require 'spec_helper'

describe 'cloud::storage::rbd::osd' do

  shared_examples_for 'ceph osd' do

    let :pre_condition do
      "class { 'cloud::storage::rbd':
        fsid            => '123',
        cluster_network => '10.0.0.0/24',
        public_network  => '192.168.0.0/24' }"
    end

    let :params do
      { :public_address  => '10.0.0.1',
        :cluster_address => '192.168.0.1',
        :devices         => ['sdb','sdc','sdd'] }
    end

    it 'configure ceph common' do
      should contain_class('ceph::conf').with(
        :fsid            => '123',
        :auth_type       => 'cephx',
        :cluster_network => '10.0.0.0/24',
        :public_network  => '192.168.0.0/24',
        :enable_service  => true
      )
    end

    it 'configure ceph osd' do
      should contain_class('ceph::osd').with(
        :public_address  => '10.0.0.1',
        :cluster_address => '192.168.0.1'
      )
      should contain_ceph__osd__device('/dev/sdb','/dev/sdc','/dev/sdd')
    end

  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily       => 'Debian',
        :concat_basedir => '/var/lib/puppet/concat',
        :uniqueid       => '123' }
    end

    it_configures 'ceph osd'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily       => 'RedHat',
        :concat_basedir => '/var/lib/puppet/concat',
        :uniqueid       => '123' }
    end
    it_configures 'ceph osd'
  end

end

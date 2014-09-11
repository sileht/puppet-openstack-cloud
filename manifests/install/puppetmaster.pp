#
# Copyright (C) 2014 eNovance SAS <licensing@enovance.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# == Class: cloud::install::puppetmaster
#
# Configure the puppet master on the install-server
#
# == Parameters:
#
#  [*main_configuration*]
#    (optional) Hash of ini settings to set in the main section of the configuration
#    Default: {}
#
#  [*agent_configuration*]
#    (optional) Hash of ini settings to set in the agent section of the configuration
#    Default: {}
#
#  [*master_configuration*]
#    (optional) Hash of ini settings to set in the master section of the configuration
#    Default: {}
#
#  [*puppetconf_path*]
#    (optional) Path to the puppet master configuration file
#    Default: /etc/puppet/puppet.conf
#
class cloud::install::puppetmaster (
  $main_configuration   = {},
  $agent_configuration  = {},
  $master_configuration = {},
  $puppetconf_path      = '/etc/puppet/puppet.conf',
) {


  # TODO (spredzy) : Currently an issue arise
  # when using facter into hiera files hence
  # we declare everything manually
  class { 'hiera' :
    datadir   => '/etc/puppet/data',
    hierarchy => [
      '%{::type}/%{::fqdn}',
      '%{::type}/common}',
      'common',
    ]
  }

  include ::puppetdb::master::config

  create_resources('ini_setting', $main_configuration, { 'section' => 'main', 'path' => $puppetconf_path })
  create_resources('ini_setting', $agent_configuration, { 'section' => 'agent', 'path' => $puppetconf_path })
  create_resources('ini_setting', $master_configuration, { 'section' => 'master', 'path' => $puppetconf_path })

}

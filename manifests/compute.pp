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
# == Class: cloud::compute
#
# Common class for compute nodes
#
# === Parameters:
#
# [*nova_db_host*]
#   (optional) Hostname or IP address to connect to nova database
#   Defaults to '127.0.0.1'
#
# [*nova_db_user*]
#   (optional) Username to connect to nova database
#   Defaults to 'nova'
#
# [*nova_db_password*]
#   (optional) Password to connect to nova database
#   Defaults to 'novapassword'
#
# [*rabbit_hosts*]
#   (optional) List of RabbitMQ servers. Should be an array.
#   Defaults to ['127.0.0.1:5672']
#
# [*rabbit_password*]
#   (optional) Password to connect to nova queues.
#   Defaults to 'rabbitpassword'
#
# [*rabbit_use_ssl*]
#   (optional) Connect over SSL for RabbitMQ
#   Defaults to false
#
# [*kombu_ssl_ca_certs*]
#   (optional) SSL certification authority file (valid only if SSL enabled).
#   Defaults to undef
#
# [*kombu_ssl_certfile*]
#   (optional) SSL cert file (valid only if SSL enabled).
#   Defaults to undef
#
# [*kombu_ssl_keyfile*]
#   (optional) SSL key file (valid only if SSL enabled).
#   Defaults to undef
#
# [*kombu_ssl_version*]
#   (optional) SSL version to use (valid only if SSL enabled).
#   Valid values are TLSv1, SSLv23 and SSLv3. SSLv2 may be
#   available on some distributions.
#   Defaults to 'SSLv3'
#
# [*ks_glance_internal_host*]
#   (optional) Internal Hostname or IP to connect to Glance API
#   Defaults to '127.0.0.1'
#
# [*glance_api_port*]
#   (optional) TCP port to connect to Glance API
#   Defaults to '9292'
#
# [*verbose*]
#   (optional) Set log output to verbose output
#   Defaults to true
#
# [*debug*]
#   (optional) Set log output to debug output
#   Defaults to true
#
# [*use_syslog*]
#   (optional) Use syslog for logging
#   Defaults to true
#
# [*log_facility*]
#   (optional) Syslog facility to receive log lines
#   Defaults to 'LOG_LOCAL0'
#
# [*memcache_servers*]
#   (optionnal) Memcached servers used by Keystone. Should be an array.
#   Defaults to ['127.0.0.1:11211']
#
# [*ssl*]
#   (optional) Enable SSL on the API server
#   Defaults to false, not set
#
# [*ssl_cacert*]
#   (required with ssl) CA certificate to use for SSL support.
#
# [*ssl_cert*]
#   (required with ssl) Certificate to use for SSL support.
#
# [*ssl_key*]
#   (required with ssl) Private key to use for SSL support.
#
class cloud::compute(
  $nova_db_host            = '127.0.0.1',
  $nova_db_user            = 'nova',
  $nova_db_password        = 'novapassword',
  $rabbit_hosts            = ['127.0.0.1:5672'],
  $rabbit_password         = 'rabbitpassword',
  $rabbit_use_ssl          = false,
  $kombu_ssl_ca_certs      = undef,
  $kombu_ssl_certfile      = undef,
  $kombu_ssl_keyfile       = undef,
  $kombu_ssl_version       = 'SSLv3',
  $ks_glance_internal_host = '127.0.0.1',
  $glance_api_port         = 9292,
  $verbose                 = true,
  $debug                   = true,
  $use_syslog              = true,
  $log_facility            = 'LOG_LOCAL0',
  $neutron_endpoint        = '127.0.0.1',
  $neutron_protocol        = 'http',
  $neutron_password        = 'neutronpassword',
  $neutron_region_name     = 'RegionOne',
  $memcache_servers        = ['127.0.0.1:11211'],
  $availability_zone       = 'RegionOne',
  $ssl                     = false,
  $ssl_cacert              = false,
  $ssl_cert                = false,
  $ssl_key                 = false,
) {

  if !defined(Resource['nova_config']) {
    resources { 'nova_config':
      purge => true;
    }
  }

  # Disable twice logging if syslog is enabled
  if $use_syslog {
    $log_dir = false
  } else {
    $log_dir = '/var/log/nova'
  }

  $encoded_user     = uriescape($nova_db_user)
  $encoded_password = uriescape($nova_db_password)

  class { 'nova':
    database_connection => "mysql://${encoded_user}:${encoded_password}@${nova_db_host}/nova?charset=utf8",
    rabbit_userid       => 'nova',
    rabbit_hosts        => $rabbit_hosts,
    rabbit_password     => $rabbit_password,
    rabbit_use_ssl      => $rabbit_use_ssl,
    kombu_ssl_ca_certs  => $kombu_ssl_ca_certs,
    kombu_ssl_certfile  => $kombu_ssl_certfile,
    kombu_ssl_keyfile   => $kombu_ssl_keyfile,
    kombu_ssl_version   => $kombu_ssl_version,
    glance_api_servers  => "http://${ks_glance_internal_host}:${glance_api_port}",
    memcached_servers   => $memcache_servers,
    verbose             => $verbose,
    debug               => $debug,
    log_dir             => $log_dir,
    log_facility        => $log_facility,
    use_syslog          => $use_syslog,
    use_ssl             => $ssl,
    ca_file             => $ssl_cacert,
    cert_file           => $ssl_cert,
    key_file            => $ssl_key,
  }

  class { 'nova::network::neutron':
      neutron_admin_password       => $neutron_password,
      neutron_admin_auth_url       => "${neutron_protocol}://${neutron_endpoint}:35357/v2.0",
      neutron_url                  => "${neutron_protocol}://${neutron_endpoint}:9696",
      neutron_region_name          => $neutron_region_name,
      neutron_ca_certificates_file => $ssl_cacert,
  }

  nova_config {
    'DEFAULT/resume_guests_state_on_host_boot': value => true;
    'DEFAULT/default_availability_zone':        value => $availability_zone;
    'DEFAULT/servicegroup_driver':              value => 'mc';
    'DEFAULT/glance_num_retries':               value => '10';
  }

  # Note(EmilienM):
  # We check if DB tables are created, if not we populate Nova DB.
  # It's a hack to fit with our setup where we run MySQL/Galera
  # TODO(Gonéri)
  # We have to do this only on the primary node of the galera cluster to avoid race condition
  # https://github.com/enovance/puppet-openstack-cloud/issues/156
  exec {'nova_db_sync':
    command => 'nova-manage db sync',
    user    => 'nova',
    path    => '/usr/bin',
    unless  => "/usr/bin/mysql nova -h ${nova_db_host} -u ${encoded_user} -p${encoded_password} -e \"show tables\" | /bin/grep Tables"
  }

}

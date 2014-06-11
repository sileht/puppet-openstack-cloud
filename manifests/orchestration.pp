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
# == Class: cloud::orchestration
#
# Orchestration common node
#
# === Parameters:
#
# [*ks_keystone_internal_host*]
#   (optional) Internal Hostname or IP to connect to Keystone API
#   Defaults to '127.0.0.1'
#
# [*ks_keystone_admin_host*]
#   (optional) Admin Hostname or IP to connect to Keystone API
#   Defaults to '127.0.0.1'
#
# [*ks_keystone_internal_port*]
#   (optional) TCP port to connect to Keystone API from internal network
#   Defaults to '5000'
#
# [*ks_keystone_admin_port*]
#   (optional) TCP port to connect to Keystone API from admin network
#   Defaults to '35357'
#
# [*ks_keystone_internal_proto*]
#   (optional) Protocol used to connect to API. Could be 'http' or 'https'.
#   Defaults to 'http'
#
# [*ks_keystone_admin_proto*]
#   (optional) Protocol used to connect to API. Could be 'http' or 'https'.
#   Defaults to 'http'
#
# [*ks_heat_public_host*]
#   (optional) Public Hostname or IP to connect to Heat API
#   Defaults to '127.0.0.1'
#
# [*ks_heat_public_proto*]
#   (optional) Protocol used to connect to API. Could be 'http' or 'https'.
#   Defaults to 'http'
#
# [*ks_heat_password*]
#   (optional) Password used by Heat to connect to Keystone API
#   Defaults to 'heatpassword'
#
# [*heat_db_host*]
#   (optional) Hostname or IP address to connect to heat database
#   Defaults to '127.0.0.1'
#
# [*heat_db_user*]
#   (optional) Username to connect to heat database
#   Defaults to 'heat'
#
# [*heat_db_password*]
#   (optional) Password to connect to heat database
#   Defaults to 'heatpassword'
#
# [*rabbit_hosts*]
#   (optional) List of RabbitMQ servers. Should be an array.
#   Defaults to ['127.0.0.1:5672']
#
# [*rabbit_password*]
#   (optional) Password to connect to heat queues.
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

class cloud::orchestration(
  $ks_keystone_internal_host  = '127.0.0.1',
  $ks_keystone_internal_port  = '5000',
  $ks_keystone_internal_proto = 'http',
  $ks_keystone_admin_host     = '127.0.0.1',
  $ks_keystone_admin_port     = '35357',
  $ks_keystone_admin_proto    = 'http',
  $ks_heat_public_host        = '127.0.0.1',
  $ks_heat_public_proto       = 'http',
  $ks_heat_password           = 'heatpassword',
  $heat_db_host               = '127.0.0.1',
  $heat_db_user               = 'heat',
  $heat_db_password           = 'heatpassword',
  $rabbit_hosts               = ['127.0.0.1:5672'],
  $rabbit_password            = 'rabbitpassword',
  $rabbit_use_ssl             = false,
  $kombu_ssl_ca_certs         = undef,
  $kombu_ssl_certfile         = undef,
  $kombu_ssl_keyfile          = undef,
  $kombu_ssl_version          = 'SSLv3',
  $verbose                    = true,
  $debug                      = true,
  $use_syslog                 = true,
  $log_facility               = 'LOG_LOCAL0'
) {

  # Disable twice logging if syslog is enabled
  if $use_syslog {
    $log_dir = false
  } else {
    $log_dir = '/var/log/heat'
  }

  $encoded_user     = uriescape($heat_db_user)
  $encoded_password = uriescape($heat_db_password)

  class { 'heat':
    keystone_host      => $ks_keystone_admin_host,
    keystone_port      => $ks_keystone_admin_port,
    keystone_protocol  => $ks_keystone_admin_proto,
    keystone_password  => $ks_heat_password,
    auth_uri           => "${ks_keystone_internal_proto}://${ks_keystone_internal_host}:${ks_keystone_internal_port}/v2.0",
    sql_connection     => "mysql://${encoded_user}:${encoded_password}@${heat_db_host}/heat?charset=utf8",
    rabbit_hosts       => $rabbit_hosts,
    rabbit_password    => $rabbit_password,
    rabbit_userid      => 'heat',
    rabbit_use_ssl     => $rabbit_use_ssl,
    kombu_ssl_ca_certs => $kombu_ssl_ca_certs,
    kombu_ssl_certfile => $kombu_ssl_certfile,
    kombu_ssl_keyfile  => $kombu_ssl_keyfile,
    kombu_ssl_version  => $kombu_ssl_version,
    verbose            => $verbose,
    debug              => $debug,
    log_facility       => $log_facility,
    use_syslog         => $use_syslog,
    log_dir            => $log_dir,
  }

  # Note(EmilienM):
  # We check if DB tables are created, if not we populate Heat DB.
  # It's a hack to fit with our setup where we run MySQL/Galera
  # TODO(Gonéri)
  # We have to do this only on the primary node of the galera cluster to avoid race condition
  # https://github.com/enovance/puppet-openstack-cloud/issues/156
  exec {'heat_db_sync':
    command => 'heat-manage --config-file /etc/heat/heat.conf db_sync',
    path    => '/usr/bin',
    user    => 'heat',
    unless  => "/usr/bin/mysql heat -h ${heat_db_host} -u ${encoded_user} -p${encoded_password} -e \"show tables\" | /bin/grep Tables"
  }

}

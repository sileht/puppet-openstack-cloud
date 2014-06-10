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
# == Class: cloud::image::registry
#
# Install Registry Image Server (Glance Registry)
#
# === Parameters:
#
# [*glance_db_host*]
#   (optional) Hostname or IP address to connect to glance database
#   Defaults to '127.0.0.1'
#
# [*glance_db_user*]
#   (optional) Username to connect to glance database
#   Defaults to 'glance'
#
# [*glance_db_password*]
#   (optional) Password to connect to glance database
#   Defaults to 'glancepassword'
#
# [*ks_keystone_internal_host*]
#   (optional) Internal Hostname or IP to connect to Keystone API
#   Defaults to '127.0.0.1'
#
# [*ks_glance_registry_internal_port*]
#   (optional) TCP port to connect to Glance Registry from internal network
#   Defaults to '9191'
#
# [*ks_glance_password*]
#   (optional) Password used by Glance to connect to Keystone API
#   Defaults to 'glancepassword'
#
# [*api_eth*]
#   (optional) Which interface we bind the Glance API server.
#   Defaults to '127.0.0.1'
#
# [*use_syslog*]
#   (optional) Use syslog for logging
#   Defaults to true
#
# [*log_facility*]
#   (optional) Syslog facility to receive log lines
#   Defaults to 'LOG_LOCAL0'
#
# [*ssl*]
#   (optional) Enable SSL support
#   Defaults to false
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
class cloud::image::registry(
  $glance_db_host                   = '127.0.0.1',
  $glance_db_user                   = 'glance',
  $glance_db_password               = 'glancepassword',
  $ks_keystone_internal_host        = '127.0.0.1',
  $ks_glance_internal_host          = '127.0.0.1',
  $ks_glance_registry_internal_port = '9191',
  $ks_glance_password               = 'glancepassword',
  $api_eth                          = '127.0.0.1',
  $verbose                          = true,
  $debug                            = true,
  $log_facility                     = 'LOG_LOCAL0',
  $use_syslog                       = true,
  $ssl                              = false,
  $ssl_cacert                       = false,
  $ssl_cert                         = false,
  $ssl_key                          = false,
) {

  # Disable twice logging if syslog is enabled
  if $use_syslog {
    $log_dir           = false
    $log_file_api      = false
    $log_file_registry = false
  } else {
    $log_dir           = '/var/log/glance'
    $log_file_api      = '/var/log/glance/api.log'
    $log_file_registry = '/var/log/glance/registry.log'
  }

  if $ssl {
    if !$ssl_cacert {
      fail('The ssl_cacert parameter is required when ssl is set to true')
    }
    if !$ssl_cert {
      fail('The ssl_cert parameter is required when ssl is set to true')
    }
    if !$ssl_key {
      fail('The ssl_key parameter is required when ssl is set to true')
    }
  }

  $encoded_glance_user     = uriescape($glance_db_user)
  $encoded_glance_password = uriescape($glance_db_password)

  class { 'glance::registry':
    database_connection => "mysql://${encoded_glance_user}:${encoded_glance_password}@${glance_db_host}/glance?charset=utf8",
    verbose             => $verbose,
    debug               => $debug,
    auth_host           => $ks_keystone_internal_host,
    keystone_password   => $ks_glance_password,
    keystone_tenant     => 'services',
    keystone_user       => 'glance',
    bind_host           => $api_eth,
    log_dir             => $log_dir,
    log_file            => $log_file_registry,
    bind_port           => $ks_glance_registry_internal_port,
    use_syslog          => $use_syslog,
    log_facility        => $log_facility,
    cert_file           => $ssl_cert,
    key_file            => $ssl_key,
    ca_file             => $ssl_cacert,
  }

  exec {'glance_db_sync':
    command => 'glance-manage db_sync',
    user    => 'glance',
    path    => '/usr/bin',
    unless  => "/usr/bin/mysql glance -h ${glance_db_host} -u ${encoded_glance_user} -p${encoded_glance_password} -e \"show tables\" | /bin/grep Tables"
  }

  @@haproxy::balancermember{"${::fqdn}-glance_registry":
    listening_service => 'glance_registry_cluster',
    server_names      => $::hostname,
    ipaddresses       => $api_eth,
    ports             => $ks_glance_registry_internal_port,
    options           => 'check inter 2000 rise 2 fall 5'
  }
}

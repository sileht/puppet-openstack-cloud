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
# == Class: cloud::image::api
#
# Install API Image Server (Glance API)
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
# [*ks_glance_api_internal_port*]
#   (optional) TCP port to connect to Glance API from internal network
#   Defaults to '9292'
#
# [*ks_glance_registry_internal_port*]
#   (optional) TCP port to connect to Glance Registry from internal network
#   Defaults to '9191'
#
# [*ks_glance_password*]
#   (optional) Password used by Glance to connect to Keystone API
#   Defaults to 'glancepassword'
#
# [*rabbit_host*]
#   (optional) IP or Hostname of one RabbitMQ server.
#   Defaults to '127.0.0.1'
#
# [*rabbit_password*]
#   (optional) Password to connect to glance queue.
#   Defaults to 'rabbitpassword'
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
# [*backend*]
#   (optionnal) Backend to use to store images
#   Can be 'rbd' or 'file'.
#   Defaults to 'rbd' to maintain backward compatibility
#
class cloud::image::api(
  $glance_db_host                    = '127.0.0.1',
  $glance_db_user                    = 'glance',
  $glance_db_password                = 'glancepassword',
  $ks_keystone_internal_host         = '127.0.0.1',
  $ks_keystone_internal_proto        = 'http',
  $ks_glance_internal_host           = '127.0.0.1',
  $ks_glance_api_internal_port       = '9292',
  $ks_glance_registry_internal_port  = '9191',
  $ks_glance_registry_internal_proto = 'http',
  $ks_glance_password                = 'glancepassword',
  $rabbit_password                   = 'rabbit_password',
  $rabbit_host                       = '127.0.0.1',
  $api_eth                           = '127.0.0.1',
  $openstack_vip                     = '127.0.0.1',
  $glance_rbd_pool                   = 'images',
  $glance_rbd_user                   = 'glance',
  $verbose                           = true,
  $debug                             = true,
  $log_facility                      = 'LOG_LOCAL0',
  $use_syslog                        = true,
  $backend                           = 'rbd',
  $filesystem_store_datadir          = undef
) {

  # Disable twice logging if syslog is enabled
  if $use_syslog {
    $log_dir           = false
    $log_file_api      = false
    $log_file_registry = false
    glance_api_config {
      'DEFAULT/logging_context_format_string': value => '%(process)d: %(levelname)s %(name)s [%(request_id)s %(user_identity)s] %(instance)s%(message)s';
      'DEFAULT/logging_default_format_string': value => '%(process)d: %(levelname)s %(name)s [-] %(instance)s%(message)s';
      'DEFAULT/logging_debug_format_suffix': value => '%(funcName)s %(pathname)s:%(lineno)d';
      'DEFAULT/logging_exception_prefix': value => '%(process)d: TRACE %(name)s %(instance)s';
    }
  } else {
    $log_dir           = '/var/log/glance'
    $log_file_api      = '/var/log/glance/api.log'
    $log_file_registry = '/var/log/glance/registry.log'
  }

  $encoded_glance_user     = uriescape($glance_db_user)
  $encoded_glance_password = uriescape($glance_db_password)

  class { 'glance::api':
    database_connection      => "mysql://${encoded_glance_user}:${encoded_glance_password}@${glance_db_host}/glance?charset=utf8",
    mysql_module             => '2.2',
    registry_host            => $openstack_vip,
    registry_port            => $ks_glance_registry_internal_port,
    verbose                  => $verbose,
    debug                    => $debug,
    auth_host                => $ks_keystone_internal_host,
    auth_protocol            => $ks_keystone_internal_proto,
    registry_client_protocol => $ks_glance_registry_internal_proto,
    keystone_password        => $ks_glance_password,
    keystone_tenant          => 'services',
    keystone_user            => 'glance',
    show_image_direct_url    => true,
    log_dir                  => $log_dir,
    log_file                 => $log_file_api,
    log_facility             => $log_facility,
    bind_host                => $api_eth,
    bind_port                => $ks_glance_api_internal_port,
    use_syslog               => $use_syslog,
  }

  # TODO(EmilienM) Disabled for now
  # Follow-up: https://github.com/enovance/puppet-openstack-cloud/issues/160
  #
  # class { 'glance::notify::rabbitmq':
  #   rabbit_password => $rabbit_password,
  #   rabbit_userid   => 'glance',
  #   rabbit_host     => $rabbit_host,
  # }
  glance_api_config {
    'DEFAULT/notifier_driver':          value => 'noop';
  }

  if ($backend == 'rbd') {
    class { 'glance::backend::rbd':
      rbd_store_user => $glance_rbd_user,
      rbd_store_pool => $glance_rbd_pool
    }

    Ceph::Key <<| title == $glance_rbd_user |>> ->
    file { '/etc/ceph/ceph.client.glance.keyring':
      owner   => 'glance',
      group   => 'glance',
      mode    => '0400',
      require => Ceph::Key[$glance_rbd_user],
      notify  => Service['glance-api','glance-registry']
    }
    Concat::Fragment <<| title == 'ceph-client-os' |>>
  } elsif ($backend == 'file') {
    class { 'glance::backend::file':
      filesystem_store_datadir => $filesystem_store_datadir
    }
  } else {
    fail("${backend} is not a Glance supported backend.")
  }

  class { 'glance::cache::cleaner': }
  class { 'glance::cache::pruner': }

  @@haproxy::balancermember{"${::fqdn}-glance_api":
    listening_service => 'glance_api_cluster',
    server_names      => $::hostname,
    ipaddresses       => $api_eth,
    ports             => $ks_glance_api_internal_port,
    options           => 'check inter 2000 rise 2 fall 5'
  }
}

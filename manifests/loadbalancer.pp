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
# == Class: cloud::loadbalancer
#
# Install Load-Balancer node (HAproxy + Keepalived)
#
# === Parameters:
#
# [*keepalived_public_interface*]
#   (optional) Networking interface to bind the VIP connected to public network.
#   Defaults to 'eth0'
#
# [*keepalived_internal_interface*]
#   (optional) Networking interface to bind the VIP connected to internal network.
#   keepalived_internal_ipvs should be configured to enable the internal VIP.
#   Defaults to 'eth1'
#
# [*keepalived_public_ipvs*]
#   (optional) IP address of the VIP connected to public network.
#   Should be an array.
#   Defaults to ['127.0.0.1']
#
# [*keepalived_internal_ipvs*]
#   (optional) IP address of the VIP connected to internal network.
#   Should be an array.
#   Defaults to false (disabled)
#
# [*keepalived_interface*]
#   (optional) Networking interface to bind the VIP connected to internal network.
#   DEPRECATED: use keepalived_public_interface instead.
#   Defaults to false (disabled)
#
# [*keepalived_ipvs*]
#   (optional) IP address of the VIP connected to public network.
#   DEPRECATED: use keepalived_public_ipvs instead.
#   Should be an array.
#   Defaults to false (disabled)
#
# [*swift_api*]
#   (optional) Enable or not Swift public binding.
#   If true, both public and internal will attempt to be created except if vip_internal_ip is set to false (backward compatibility).
#   If set to ['10.0.0.1'], only IP in the array (or in the string) will be configured in the pool. They must be part of keepalived_ip options.
#   If set to false, no binding will be configure
#   Defaults to true
#
# [*ceilometer_api*]
#   (optional) Enable or not Ceilometer public binding.
#   If true, both public and internal will attempt to be created except if vip_internal_ip is set to false (backward compatibility).
#   If set to ['10.0.0.1'], only IP in the array (or in the string) will be configured in the pool. They must be part of keepalived_ip options.
#   If set to false, no binding will be configure
#   Defaults to true
#
# [*cinder_api*]
#   (optional) Enable or not Cinder public binding.
#   If true, both public and internal will attempt to be created except if vip_internal_ip is set to false (backward compatibility).
#   If set to ['10.0.0.1'], only IP in the array (or in the string) will be configured in the pool. They must be part of keepalived_ip options.
#   If set to false, no binding will be configure
#   Defaults to true
#
# [*glance_api*]
#   (optional) Enable or not Glance API public binding.
#   If true, both public and internal will attempt to be created except if vip_internal_ip is set to false (backward compatibility).
#   If set to ['10.0.0.1'], only IP in the array (or in the string) will be configured in the pool. They must be part of keepalived_ip options.
#   If set to false, no binding will be configure
#   Defaults to true
#
# [*glance_registry*]
#   (optional) Enable or not Glance Registry public binding.
#   If true, both public and internal will attempt to be created except if vip_internal_ip is set to false (backward compatibility).
#   If set to ['10.0.0.1'], only IP in the array (or in the string) will be configured in the pool. They must be part of keepalived_ip options.
#   If set to false, no binding will be configure
#   Defaults to true
#
# [*neutron_api*]
#   (optional) Enable or not Neutron public binding.
#   If true, both public and internal will attempt to be created except if vip_internal_ip is set to false (backward compatibility).
#   If set to ['10.0.0.1'], only IP in the array (or in the string) will be configured in the pool. They must be part of keepalived_ip options.
#   If set to false, no binding will be configure
#   Defaults to true
#
# [*heat_api*]
#   (optional) Enable or not Heat public binding.
#   If true, both public and internal will attempt to be created except if vip_internal_ip is set to false (backward compatibility).
#   If set to ['10.0.0.1'], only IP in the array (or in the string) will be configured in the pool. They must be part of keepalived_ip options.
#   If set to false, no binding will be configure
#   Defaults to true
#
# [*heat_cfn_api*]
#   (optional) Enable or not Heat CFN public binding.
#   If true, both public and internal will attempt to be created except if vip_internal_ip is set to false (backward compatibility).
#   If set to ['10.0.0.1'], only IP in the array (or in the string) will be configured in the pool. They must be part of keepalived_ip options.
#   If set to false, no binding will be configure
#   Defaults to true
#
# [*heat_cloudwatch_api*]
#   (optional) Enable or not Heat Cloudwatch public binding.
#   If true, both public and internal will attempt to be created except if vip_internal_ip is set to false (backward compatibility).
#   If set to ['10.0.0.1'], only IP in the array (or in the string) will be configured in the pool. They must be part of keepalived_ip options.
#   If set to false, no binding will be configure
#   Defaults to true
#
# [*nova_api*]
#   (optional) Enable or not Nova public binding.
#   If true, both public and internal will attempt to be created except if vip_internal_ip is set to false (backward compatibility).
#   If set to ['10.0.0.1'], only IP in the array (or in the string) will be configured in the pool. They must be part of keepalived_ip options.
#   If set to false, no binding will be configure
#   Defaults to true
#
# [*trove_api*]
#   (optional) Enable or not Trove public binding.
#   If true, both public and internal will attempt to be created except if vip_internal_ip is set to false (backward compatibility).
#   If set to ['10.0.0.1'], only IP in the array (or in the string) will be configured in the pool. They must be part of keepalived_ip options.
#   If set to false, no binding will be configure
#   Defaults to true
#
# [*ec2_api*]
#   (optional) Enable or not EC2 public binding.
#   If true, both public and internal will attempt to be created except if vip_internal_ip is set to false (backward compatibility).
#   If set to ['10.0.0.1'], only IP in the array (or in the string) will be configured in the pool. They must be part of keepalived_ip options.
#   If set to false, no binding will be configure
#   Defaults to true
#
# [*metadata_api*]
#   (optional) Enable or not Metadata public binding.
#   If true, both public and internal will attempt to be created except if vip_internal_ip is set to false (backward compatibility).
#   If set to ['10.0.0.1'], only IP in the array (or in the string) will be configured in the pool. They must be part of keepalived_ip options.
#   If set to false, no binding will be configure
#   Defaults to true
#
# [*keystone_api*]
#   (optional) Enable or not Keystone public binding.
#   If true, both public and internal will attempt to be created except if vip_internal_ip is set to false (backward compatibility).
#   If set to ['10.0.0.1'], only IP in the array (or in the string) will be configured in the pool. They must be part of keepalived_ip options.
#   If set to false, no binding will be configure
#   Defaults to true
#
# [*keystone_api_admin*]
#   (optional) Enable or not Keystone admin binding.
#   If true, both public and internal will attempt to be created except if vip_internal_ip is set to false (backward compatibility).
#   If set to ['10.0.0.1'], only IP in the array (or in the string) will be configured in the pool. They must be part of keepalived_ip options.
#   If set to false, no binding will be configure
#   Defaults to true
#
# [*vip_public_ip*]
#  (optional) Array or string for public VIP
#  Should be part of keepalived_public_ips
#  Defaults to '127.0.0.2'
#
# [*vip_internal_ip*]
#  (optional) Array or string for internal VIP
#  Should be part of keepalived_internal_ips
#  Defaults to false (backward compatibility)
class cloud::loadbalancer(
  $swift_api                        = true,
  $ceilometer_api                   = true,
  $cinder_api                       = true,
  $glance_api                       = true,
  $glance_registry                  = true,
  $neutron_api                      = true,
  $heat_api                         = true,
  $heat_cfn_api                     = true,
  $heat_cloudwatch_api              = true,
  $nova_api                         = true,
  $ec2_api                          = true,
  $metadata_api                     = true,
  $keystone_api                     = true,
  $keystone_api_admin               = true,
  $trove_api                        = true,
  $horizon                          = true,
  $spice                            = true,
  $haproxy_auth                     = 'admin:changeme',
  $keepalived_state                 = 'BACKUP',
  $keepalived_priority              = '50',
  $keepalived_public_interface      = 'eth0',
  $keepalived_public_ipvs           = ['127.0.0.1'],
  $keepalived_internal_interface    = 'eth1',
  $keepalived_internal_ipvs         = false,
  $ceilometer_bind_options          = [],
  $cinder_bind_options              = [],
  $ec2_bind_options                 = [],
  $glance_api_bind_options          = [],
  $glance_registry_bind_options     = [],
  $heat_cfn_bind_options            = [],
  $heat_cloudwatch_bind_options     = [],
  $heat_api_bind_options            = [],
  $keystone_bind_options            = [],
  $keystone_admin_bind_options      = [],
  $metadata_bind_options            = [],
  $neutron_bind_options             = [],
  $nova_bind_options                = [],
  $trove_bind_options               = [],
  $swift_bind_options               = [],
  $spice_bind_options               = [],
  $horizon_bind_options             = [],
  $galera_bind_options              = [],
  $ks_ceilometer_public_port        = 8777,
  $ks_cinder_public_port            = 8776,
  $ks_ec2_public_port               = 8773,
  $ks_glance_api_public_port        = 9292,
  $ks_glance_registry_internal_port = 9191,
  $ks_heat_cfn_public_port          = 8000,
  $ks_heat_cloudwatch_public_port   = 8003,
  $ks_heat_public_port              = 8004,
  $ks_keystone_admin_port           = 35357,
  $ks_keystone_public_port          = 5000,
  $ks_metadata_public_port          = 8775,
  $ks_neutron_public_port           = 9696,
  $ks_nova_public_port              = 8774,
  $ks_swift_public_port             = 8080,
  $ks_trove_public_port             = 8779,
  $horizon_port                     = 80,
  $horizon_ssl_port                 = false,
  $spice_port                       = 6082,
  $vip_public_ip                    = ['127.0.0.1'],
  $vip_internal_ip                  = false,
  $galera_ip                        = ['127.0.0.1'],
  # Deprecated parameters
  $keepalived_interface             = false,
  $keepalived_ipvs                  = false,
  $horizon_ssl                      = false,
){

  # Manage deprecation when using old parameters
  if $keepalived_interface {
    warning('keepalived_interface parameter is deprecated. Use internal/external parameters instead.')
    $keepalived_public_interface_real = $keepalived_interface
  } else {
    $keepalived_public_interface_real = $keepalived_public_interface
  }
  if $keepalived_ipvs {
    warning('keepalived_ipvs parameter is deprecated. Use internal/external parameters instead.')
    $keepalived_public_ipvs_real = $keepalived_ipvs
  } else {
    $keepalived_public_ipvs_real = $keepalived_public_ipvs
  }

  # end of deprecation support

  # Fail if OpenStack and Galera VIP are  not in the VIP list
  if $vip_public_ip and !($vip_public_ip in $keepalived_public_ipvs_real) {
    fail('vip_public_ip should be part of keepalived_public_ipvs.')
  }
  if $vip_internal_ip and !($vip_internal_ip in $keepalived_internal_ipvs) {
    fail('vip_internal_ip should be part of keepalived_internal_ipvs.')
  }
  if $galera_ip and !(($galera_ip in $keepalived_public_ipvs_real) or ($galera_ip in $keepalived_internal_ipvs)) {
    fail('galera_ip should be part of keepalived_public_ipvs or keepalived_internal_ipvs.')
  }

  # Ensure Keepalived is started before HAproxy to avoid binding errors.
  class { 'keepalived': } ->
  class { 'haproxy':
    service_manage => true
  }

  keepalived::vrrp_script { 'haproxy':
    name_is_process => true
  }

  keepalived::instance { '1':
    interface     => $keepalived_public_interface_real,
    virtual_ips   => unique(split(join(flatten([$keepalived_public_ipvs_real, ['']]), " dev ${keepalived_public_interface_real},"), ',')),
    state         => $keepalived_state,
    track_script  => ['haproxy'],
    priority      => $keepalived_priority,
    notify_master => '"/etc/init.d/haproxy start"',
    notify_backup => '"/etc/init.d/haproxy stop"',
  }

  if $keepalived_internal_ipvs {
    keepalived::instance { '2':
      interface     => $keepalived_internal_interface,
      virtual_ips   => unique(split(join(flatten([$keepalived_internal_ipvs, ['']]), " dev ${keepalived_internal_interface},"), ',')),
      state         => $keepalived_state,
      track_script  => ['haproxy'],
      priority      => $keepalived_priority,
      notify_master => '"/etc/init.d/haproxy start"',
      notify_backup => '"/etc/init.d/haproxy stop"',
    }
  }

  file { '/etc/logrotate.d/haproxy':
    ensure  => file,
    source  => 'puppet:///modules/cloud/logrotate/haproxy',
    owner   => root,
    group   => root,
    mode    => '0644';
  }

  haproxy::listen { 'monitor':
    ipaddress => $vip_public_ip,
    ports     => '9300',
    options   => {
      'mode'        => 'http',
      'monitor-uri' => '/status',
      'stats'       => ['enable','uri     /admin','realm   Haproxy\ Statistics',"auth    ${haproxy_auth}", 'refresh 5s' ],
      ''            => template('cloud/loadbalancer/monitor.erb'),
    }
  }

  # Instanciate HAproxy binding
  cloud::loadbalancer::binding { 'keystone_api_cluster':
    ip           => $keystone_api,
    port         => $ks_keystone_public_port,
    bind_options => $keystone_bind_options,
  }
  cloud::loadbalancer::binding { 'keystone_api_admin_cluster':
    ip           => $keystone_api_admin,
    port         => $ks_keystone_admin_port,
    bind_options => $keystone_admin_bind_options,
  }
  cloud::loadbalancer::binding { 'swift_api_cluster':
    ip           => $swift_api,
    port         => $ks_swift_public_port,
    bind_options => $swift_bind_options,
    httpchk      => 'httpchk /healthcheck',
  }
  cloud::loadbalancer::binding { 'nova_api_cluster':
    ip           => $nova_api,
    port         => $ks_nova_public_port,
    bind_options => $nova_bind_options,
  }
  cloud::loadbalancer::binding { 'ec2_api_cluster':
    ip           => $ec2_api,
    port         => $ks_ec2_public_port,
    bind_options => $ec2_bind_options,
  }
  cloud::loadbalancer::binding { 'metadata_api_cluster':
    ip           => $metadata_api,
    port         => $ks_metadata_public_port,
    bind_options => $metadata_bind_options,
  }
  cloud::loadbalancer::binding { 'spice_cluster':
    ip                 => $spice,
    port               => $spice_port,
    options            => {
      'balance'        => 'leastconn',
      'timeout server' => '120m',
      'timeout client' => '120m',
    },
    bind_options       => $spice_bind_options,
    httpchk            => 'httpchk GET /';
  }
  cloud::loadbalancer::binding { 'trove_api_cluster':
    ip           => $trove_api,
    port         => $ks_trove_public_port,
    bind_options => $trove_bind_options,
  }
  cloud::loadbalancer::binding { 'glance_api_cluster':
    ip                 => $glance_api,
    options            => {
      'balance'        => 'leastconn',
      'timeout server' => '120m',
      'timeout client' => '120m',
    },
    port               => $ks_glance_api_public_port,
    bind_options       => $glance_api_bind_options,
  }
  cloud::loadbalancer::binding { 'glance_registry_cluster':
    ip           => $glance_registry,
    port         => $ks_glance_registry_internal_port,
    bind_options => $glance_registry_bind_options,
  }
  cloud::loadbalancer::binding { 'neutron_api_cluster':
    ip           => $neutron_api,
    port         => $ks_neutron_public_port,
    bind_options => $neutron_bind_options,
  }
  cloud::loadbalancer::binding { 'cinder_api_cluster':
    ip           => $cinder_api,
    port         => $ks_cinder_public_port,
    bind_options => $cinder_bind_options,
  }
  cloud::loadbalancer::binding { 'ceilometer_api_cluster':
    ip           => $ceilometer_api,
    port         => $ks_ceilometer_public_port,
    bind_options => $ceilometer_bind_options,
  }
  if 'ssl' in $heat_api_bind_options {
    $heat_api_options = {
    'reqadd'  => 'X-Forwarded-Proto:\ https if { ssl_fc }' }
  } else {
    $heat_api_options = {}
  }
  cloud::loadbalancer::binding { 'heat_api_cluster':
    ip           => $heat_api,
    port         => $ks_heat_public_port,
    bind_options => $heat_api_bind_options,
    options      => $heat_api_options
  }
  if 'ssl' in $heat_cfn_bind_options {
    $heat_cfn_options = {
    'reqadd'  => 'X-Forwarded-Proto:\ https if { ssl_fc }' }
  } else {
    $heat_cfn_options = { }
  }
  cloud::loadbalancer::binding { 'heat_cfn_api_cluster':
    ip           => $heat_cfn_api,
    port         => $ks_heat_cfn_public_port,
    bind_options => $heat_cfn_bind_options,
    options      => $heat_cfn_options
  }
  if 'ssl' in $heat_cloudwatch_bind_options {
    $heat_cloudwatch_options = {
    'reqadd'  => 'X-Forwarded-Proto:\ https if { ssl_fc }' }
  } else {
    $heat_cloudwatch_options = { }
  }
  cloud::loadbalancer::binding { 'heat_cloudwatch_api_cluster':
    ip           => $heat_cloudwatch_api,
    port         => $ks_heat_cloudwatch_public_port,
    bind_options => $heat_cloudwatch_bind_options,
    options      => $heat_cloudwatch_options
  }

  if $::operatingsystem == 'RedHat' {
    $horizon_auth_url = 'dashboard'
  } else {
    $horizon_auth_url = 'horizon'
  }
  if $horizon_ssl {
    warning('horizon_ssl parameter is deprecated. Specify a valid port in horizon_ssl_port instead.')
    $horizon_httpchk = 'ssl-hello-chk'
    $horizon_options = {
      'mode'    => 'tcp',
      'cookie'  => 'sessionid prefix',
      'balance' => 'leastconn' }
  } elsif $horizon_ssl_port {
    $horizon_httpchk = 'ssl-hello-chk'
    $horizon_options = {
      'mode'    => 'tcp',
      'cookie'  => 'sessionid prefix',
      'balance' => 'leastconn' }
  } else {
    $horizon_httpchk = "httpchk GET  /${horizon_auth_url}  \"HTTP/1.0\\r\\nUser-Agent: HAproxy-${::hostname}\""
    $horizon_options = {
      'cookie'  => 'sessionid prefix',
      'balance' => 'leastconn' }
  }

  cloud::loadbalancer::binding { 'horizon_cluster':
    ip           => $vip_public_ip,
    port         => $horizon_port,
    httpchk      => $horizon_httpchk,
    options      => $horizon_options,
    bind_options => $horizon_bind_options,
  }

  if $horizon_ssl_port {
    cloud::loadbalancer::binding { 'horizon_ssl_cluster':
      ip           => $vip_public_ip,
      port         => $horizon_ssl_port,
      httpchk      => $horizon_httpchk,
      options      => $horizon_options,
      bind_options => $horizon_bind_options,
    }
  }

  if ($galera_ip in $keepalived_public_ipvs_real) {
    warning('Exposing Galera cluster to public network is a security issue.')
  }
  haproxy::listen { 'galera_cluster':
    ipaddress    => $galera_ip,
    ports        => 3306,
    options      => {
      'mode'           => 'tcp',
      'balance'        => 'roundrobin',
      'option'         => ['tcpka', 'tcplog', 'httpchk'], #httpchk mandatory expect 200 on port 9000
      'timeout client' => '400s',
      'timeout server' => '400s',
    },
    bind_options => $galera_bind_options,
  }

  # Allow HAProxy to bind to a non-local IP address
  $haproxy_sysctl_settings = {
    'net.ipv4.ip_nonlocal_bind' => { value => 1 }
  }
  create_resources(sysctl::value,$haproxy_sysctl_settings)

}

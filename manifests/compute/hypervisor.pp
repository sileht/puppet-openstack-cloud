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
# == Class: cloud::compute::hypervisor
#
# Hypervisor Compute node
#
# === Parameters:
#
# [*vm_rbd]
#   (optional) Enable or not ceph capabilities on compute node to store
#   nova instances on ceph storage.
#   Default to false.
#
# [*volume_rbd]
#   (optional) Enable or not ceph capabilities on compute node to attach
#   cinder volumes backend by ceph on nova instances.
#   Default to false.
#

class cloud::compute::hypervisor(
  $server_proxyclient_address = '127.0.0.1',
  $libvirt_type               = 'kvm',
  $ks_nova_public_proto       = 'http',
  $ks_nova_public_host        = '127.0.0.1',
  $nova_ssh_private_key       = undef,
  $nova_ssh_public_key        = undef,
  $spice_port                 = 6082,
  $cinder_rbd_user            = 'cinder',
  $nova_rbd_pool              = 'vms',
  $nova_rbd_secret_uuid       = undef,
  $vm_rbd                     = false,
  $volume_rbd                 = false,
  # set to false to keep backward compatibility
  $ks_spice_public_proto      = false,
  $ks_spice_public_host       = false,
  # DEPRECATED
  $has_ceph                   = false
) {

  include 'cloud::compute'
  include 'cloud::telemetry'
  include 'cloud::network'

  if $libvirt_type == 'kvm' and ! $::vtx {
    fail('libvirt_type is set to KVM and VTX seems to be disabled on this node.')
  }

  # Backward compatibility
  # if has_ceph was enabled, we consider deployments run Ceph for Nova & Cinder
  if $has_ceph {
    warning('has_ceph parameter is deprecated. Please use vm_rbd and volume_rbd parameters.')
    $vm_rbd_real     = true
    $volume_rbd_real = true
  } else {
    $vm_rbd_real     = $vm_rbd
    $volume_rbd_real = $volume_rbd
  }
  if $ks_spice_public_proto {
    $ks_spice_public_proto_real = $ks_spice_public_proto
  } else {
    $ks_spice_public_proto_real = $ks_nova_public_proto
  }
  if $ks_spice_public_host {
    $ks_spice_public_host_real = $ks_spice_public_host
  } else {
    $ks_spice_public_host_real = $ks_nova_public_host
  }

  file{ '/var/lib/nova/.ssh':
    ensure  => directory,
    mode    => '0700',
    owner   => 'nova',
    group   => 'nova',
    require => Class['nova']
  } ->
  file{ '/var/lib/nova/.ssh/id_rsa':
    ensure  => present,
    mode    => '0600',
    owner   => 'nova',
    group   => 'nova',
    content => $nova_ssh_private_key
  } ->
  file{ '/var/lib/nova/.ssh/authorized_keys':
    ensure  => present,
    mode    => '0600',
    owner   => 'nova',
    group   => 'nova',
    content => $nova_ssh_public_key
  } ->
  file{ '/var/lib/nova/.ssh/config':
    ensure  => present,
    mode    => '0600',
    owner   => 'nova',
    group   => 'nova',
    content => "
Host *
    StrictHostKeyChecking no
"
  }

  class { 'nova::compute':
    enabled         => true,
    vnc_enabled     => false,
    #TODO(EmilienM) Bug #1259545 currently WIP:
    virtio_nic      => false,
    neutron_enabled => true
  }

  class { 'nova::compute::spice':
    server_listen              => '0.0.0.0',
    server_proxyclient_address => $server_proxyclient_address,
    proxy_host                 => $ks_spice_public_host_real,
    proxy_protocol             => $ks_spice_public_proto_real,
    proxy_port                 => $spice_port

  }

  if $::osfamily == 'RedHat' {
    file { '/etc/libvirt/qemu.conf':
      ensure => file,
      source => 'puppet:///modules/cloud/qemu/qemu.conf',
      owner  => root,
      group  => root,
      mode   => '0644',
      notify => Service['libvirtd']
    }
    # Nova support for RBD backend is not supported in Red Hat packages
    if $has_ceph or $vm_rbd {
      fail('Red Hat does not support RBD backend for VMs.')
    }
  } else {
    # Disabling or not TSO/GSO/GRO on Debian systems
    if $::kernelmajversion >= '3.14' {
      ensure_resource ('exec','enable-tso-script', {
        'command' => '/usr/sbin/update-rc.d disable-tso defaults',
        'unless'  => '/bin/ls /etc/rc*.d | /bin/grep disable-tso',
        'onlyif'  => 'test -f /etc/init.d/disable-tso'
      })
      ensure_resource ('exec','start-tso-script', {
        'command' => '/etc/init.d/disable-tso start',
        'unless'  => 'test -f /tmp/disable-tso-lock',
        'onlyif'  => 'test -f /etc/init.d/disable-tso'
      })

    }
  }

  if $::operatingsystem == 'Ubuntu' {
    service { 'dbus':
      ensure => running,
      enable => true,
      before => Class['nova::compute::libvirt'],
    }
  }

  Service<| title == 'dbus' |> { enable => true }

  Service<| title == 'libvirt-bin' |> { enable => true }

  class { 'nova::compute::neutron': }

  if $vm_rbd_real or $volume_rbd_real {

    include 'cloud::storage::rbd'

    $libvirt_disk_cachemodes_real = ['network=writeback']

    # when nova uses ceph for instances storage
    if $vm_rbd_real {
      class { 'nova::compute::rbd':
        libvirt_rbd_user        => $cinder_rbd_user,
        libvirt_images_rbd_pool => $nova_rbd_pool
      }
    } else {
      # when nova only needs to attach ceph volumes to instances
      nova_config {
        'libvirt/rbd_user': value => $cinder_rbd_user;
      }
    }
    # we don't want puppet-nova manages keyring
    nova_config {
      'libvirt/rbd_secret_uuid': value => $nova_rbd_secret_uuid;
    }

    File <<| tag == 'ceph_compute_secret_file' |>>
    Exec <<| tag == 'get_or_set_virsh_secret' |>>

    # After setting virsh key, we need to restart nova-compute
    # otherwise nova will fail to connect to RADOS.
    Exec <<| tag == 'set_secret_value_virsh' |>> ~> Service['nova-compute']

    # If Cinder & Nova reside on the same node, we need a group
    # where nova & cinder users have read permissions.
    ensure_resource('group', 'cephkeyring', {
      ensure => 'present'
    })

    ensure_resource ('exec','add-nova-to-group', {
      'command' => 'usermod -a -G cephkeyring nova',
      'path'    => ['/usr/sbin', '/usr/bin', '/bin', '/sbin'],
      'unless'  => 'groups nova | grep cephkeyring'
    })

    # Configure Ceph keyring
    Ceph::Key <<| title == $cinder_rbd_user |>>
    if defined(Ceph::Key[$cinder_rbd_user]) {
      ensure_resource(
        'file',
        "/etc/ceph/ceph.client.${cinder_rbd_user}.keyring", {
          owner   => 'root',
          group   => 'cephkeyring',
          mode    => '0440',
          require => Ceph::Key[$cinder_rbd_user],
          notify  => Service['nova-compute'],
        }
      )
    }

    Concat::Fragment <<| title == 'ceph-client-os' |>>
  } else {
    $libvirt_disk_cachemodes_real = []
  }

  class { 'nova::compute::libvirt':
    libvirt_type            => $libvirt_type,
    # Needed to support migration but we still use Spice:
    vncserver_listen        => '0.0.0.0',
    migration_support       => true,
    libvirt_disk_cachemodes => $libvirt_disk_cachemodes_real
  }

  # Extra config for nova-compute
  nova_config {
    'libvirt/inject_key':            value => false;
    'libvirt/inject_partition':      value => '-2';
    'libvirt/live_migration_flag':   value => 'VIR_MIGRATE_UNDEFINE_SOURCE,VIR_MIGRATE_PEER2PEER,VIR_MIGRATE_LIVE,VIR_MIGRATE_PERSIST_DEST';
    'libvirt/block_migration_flag':  value => 'VIR_MIGRATE_UNDEFINE_SOURCE,VIR_MIGRATE_PEER2PEER,VIR_MIGRATE_LIVE,VIR_DOMAIN_BLOCK_REBASE_COPY,VIR_DOMAIN_BLOCK_REBASE_SHALLOW';
  }

  class { 'ceilometer::agent::compute': }

}

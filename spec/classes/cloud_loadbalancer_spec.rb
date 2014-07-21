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
# Unit tests for cloud::loadbalancer class
#

require 'spec_helper'

describe 'cloud::loadbalancer' do

  shared_examples_for 'openstack loadbalancer' do

    let :params do
      { :ceilometer_api                    => true,
        :cinder_api                        => true,
        :glance_api                        => true,
        :neutron_api                       => true,
        :heat_api                          => true,
        :heat_cfn_api                      => true,
        :heat_cloudwatch_api               => true,
        :nova_api                          => true,
        :ec2_api                           => true,
        :metadata_api                      => true,
        :swift_api                         => true,
        :keystone_api_admin                => true,
        :keystone_api                      => true,
        :trove_api                         => true,
        :horizon                           => true,
        :spice                             => true,
        :ceilometer_bind_options           => [],
        :cinder_bind_options               => [],
        :ec2_bind_options                  => [],
        :glance_api_bind_options           => [],
        :glance_registry_bind_options      => [],
        :heat_cfn_bind_options             => [],
        :heat_cloudwatch_bind_options      => [],
        :heat_api_bind_options             => [],
        :keystone_bind_options             => [],
        :keystone_admin_bind_options       => [],
        :metadata_bind_options             => [],
        :neutron_bind_options              => [],
        :trove_bind_options                => [],
        :swift_bind_options                => [],
        :spice_bind_options                => [],
        :horizon_bind_options              => [],
        :galera_bind_options               => [],
        :haproxy_auth                      => 'root:secrete',
        :keepalived_state                  => 'BACKUP',
        :keepalived_priority               => 50,
        :keepalived_public_interface       => 'eth0',
        :keepalived_public_ipvs            => ['10.0.0.1', '10.0.0.2'],
        :horizon_port                      => '80',
        :spice_port                        => '6082',
        :vip_public_ip                     => '10.0.0.1',
        :galera_ip                         => '10.0.0.2',
        :horizon_ssl                       => false,
        :horizon_ssl_port                  => false,
        :ks_ceilometer_public_port         => '8777',
        :ks_nova_public_port               => '8774',
        :ks_ec2_public_port                => '8773',
        :ks_metadata_public_port           => '8777',
        :ks_glance_api_public_port         => '9292',
        :ks_glance_registry_internal_port  => '9191',
        :ks_swift_public_port              => '8080',
        :ks_keystone_public_port           => '5000',
        :ks_keystone_admin_port            => '35357',
        :ks_cinder_public_port             => '8776',
        :ks_neutron_public_port            => '9696',
        :ks_trove_public_port              => '8779',
        :ks_heat_public_port               => '8004',
        :ks_heat_cfn_public_port           => '8000',
        :ks_heat_cloudwatch_public_port    => '8003' }
    end

    it 'configure haproxy server' do
      should contain_class('haproxy')
    end # configure haproxy server

    it 'configure keepalived server' do
      should contain_class('keepalived')
    end # configure keepalived server

    it 'configure sysctl to allow HAproxy to bind to a non-local IP address' do
      should contain_exec('exec_sysctl_net.ipv4.ip_nonlocal_bind').with_command(
        'sysctl -w net.ipv4.ip_nonlocal_bind=1'
      )
    end

    context 'configure an internal VIP' do
      before do
        params.merge!(:keepalived_internal_ipvs => ['192.168.0.1'])
      end
      it 'configure an internal VRRP instance' do
        should contain_keepalived__instance('2').with({
          'interface'     => 'eth1',
          'virtual_ips'   => ['192.168.0.1 dev eth1'],
          'track_script'  => ['haproxy'],
          'state'         => 'BACKUP',
          'priority'      => params[:keepalived_priority],
          'notify_master' => '"/etc/init.d/haproxy start"',
          'notify_backup' => '"/etc/init.d/haproxy stop"',
        })
      end
    end

    context 'configure keepalived with deprecated parameters' do
      before do
        params.merge!(
          :keepalived_ipvs      => ['192.168.0.2'],
          :vip_public_ip        => '192.168.0.2',
          :galera_ip            => '192.168.0.2',
          :keepalived_interface => 'eth3'
        )
      end
      it 'configure a public VRRP instance with deprecated parameters' do
        should contain_keepalived__instance('1').with({
          'interface'     => 'eth3',
          'virtual_ips'   => ['192.168.0.2 dev eth3'],
          'track_script'  => ['haproxy'],
          'state'         => 'BACKUP',
          'priority'      => params[:keepalived_priority],
          'notify_master' => '"/etc/init.d/haproxy start"',
          'notify_backup' => '"/etc/init.d/haproxy stop"',
        })
      end
    end

    context 'when keepalived and HAproxy are in backup' do
      it 'configure vrrp_instance with BACKUP state' do
        should contain_keepalived__instance('1').with({
          'interface'     => params[:keepalived_public_interface],
          'virtual_ips'   => ['10.0.0.1 dev eth0', '10.0.0.2 dev eth0'],
          'track_script'  => ['haproxy'],
          'state'         => params[:keepalived_state],
          'priority'      => params[:keepalived_priority],
          'notify_master' => '"/etc/init.d/haproxy start"',
          'notify_backup' => '"/etc/init.d/haproxy stop"',
        })
      end # configure vrrp_instance with BACKUP state
      it 'configure haproxy server without service managed' do
        should contain_class('haproxy').with(:service_manage => true)
      end # configure haproxy server
    end # configure keepalived in backup

    context 'configure keepalived in master' do
      before do
        params.merge!( :keepalived_state => 'MASTER' )
      end
      it 'configure vrrp_instance with MASTER state' do
        should contain_keepalived__instance('1').with({
          'interface'     => params[:keepalived_public_interface],
          'track_script'  => ['haproxy'],
          'state'         => 'MASTER',
          'priority'      => params[:keepalived_priority],
          'notify_master' => '"/etc/init.d/haproxy start"',
          'notify_backup' => '"/etc/init.d/haproxy stop"',
        })
      end
      it 'configure haproxy server with service managed' do
        should contain_class('haproxy').with(:service_manage => true)
      end # configure haproxy server
    end # configure keepalived in master

    context 'configure logrotate file' do
      it { should contain_file('/etc/logrotate.d/haproxy').with(
        :source => 'puppet:///modules/cloud/logrotate/haproxy',
        :mode   => '0644',
        :owner  => 'root',
        :group  => 'root'
      )}
    end # configure logrotate file

    context 'configure monitor haproxy listen' do
      it { should contain_haproxy__listen('monitor').with(
        :ipaddress => params[:vip_public_ip],
        :ports     => '9300'
      )}
    end # configure monitor haproxy listen

    context 'configure monitor haproxy listen' do
      it { should contain_haproxy__listen('galera_cluster').with(
        :ipaddress => params[:galera_ip],
        :ports     => '3306',
        :options   => {
          'mode'           => 'tcp',
          'balance'        => 'roundrobin',
          'option'         => ['tcpka','tcplog','httpchk'],
          'timeout client' => '400s',
          'timeout server' => '400s'
        }
      )}
    end # configure monitor haproxy listen

    # test backward compatibility
    context 'configure OpenStack binding on public network only' do
      it { should contain_haproxy__listen('spice_cluster').with(
        :ipaddress => [params[:vip_public_ip]],
        :ports     => '6082',
        :options   => {
          'mode'           => 'http',
          'option'         => ['tcpka', 'forwardfor', 'tcplog','httpchk GET /'],
          'http-check'     => 'expect ! rstatus ^5',
          'balance'        => 'leastconn',
          'timeout server' => '120m',
          'timeout client' => '120m'
        }
      )}
    end

    context 'configure OpenStack binding on both public and internal networks' do
      before do
        params.merge!(
          :nova_api               => true,
          :galera_ip              => '172.16.0.1',
          :vip_public_ip          => '172.16.0.1',
          :vip_internal_ip        => '192.168.0.1',
          :keepalived_public_ipvs => ['172.16.0.1', '172.16.0.2'],
          :keepalived_internal_ipvs => ['192.168.0.1', '192.168.0.2']
        )
      end
      it { should contain_haproxy__listen('nova_api_cluster').with(
        :ipaddress => ['172.16.0.1', '192.168.0.1'],
        :ports     => '8774'
      )}
    end

    context 'disable an OpenStack service binding' do
      before do
        params.merge!(:metadata_api => false)
      end
      it { should_not contain_haproxy__listen('metadata_api_cluster') }
    end

    context 'should fail to configure OpenStack binding when vip_public_ip and vip_internal_ip are missing' do
      before do
        params.merge!(
          :nova_api               => true,
          :galera_ip              => '172.16.0.1',
          :vip_public_ip          => false,
          :vip_internal_ip        => false,
          :keepalived_public_ipvs => ['172.16.0.1', '172.16.0.2']
        )
      end
      it_raises 'a Puppet::Error', /vip_public_ip and vip_internal_ip are both set to false, no binding is possible./
    end

    context 'should fail to configure OpenStack binding when given VIP is not in the VIP pool list' do
      before do
        params.merge!(
          :nova_api               => '10.0.0.1',
          :galera_ip              => '172.16.0.1',
          :vip_public_ip          => '172.16.0.1',
          :vip_internal_ip        => false,
          :keepalived_public_ipvs => ['172.16.0.1', '172.16.0.2']
        )
      end
      it_raises 'a Puppet::Error', /10.0.0.1 is not part of VIP pools./
    end

    context 'with a public OpenStack VIP not in the keepalived VIP list' do
      before do
        params.merge!(
          :vip_public_ip          => '172.16.0.1',
          :keepalived_public_ipvs => ['192.168.0.1', '192.168.0.2']
        )
      end
      it_raises 'a Puppet::Error', /vip_public_ip should be part of keepalived_public_ipvs./
    end

    context 'with an internal OpenStack VIP not in the keepalived VIP list' do
      before do
        params.merge!(
          :vip_internal_ip          => '172.16.0.1',
          :keepalived_internal_ipvs => ['192.168.0.1', '192.168.0.2']
        )
      end
      it_raises 'a Puppet::Error', /vip_internal_ip should be part of keepalived_internal_ipvs./
    end

    context 'with a Galera VIP not in the keepalived VIP list' do
      before do
        params.merge!(
          :galera_ip                => '172.16.0.1',
          :vip_public_ip            => '192.168.0.1',
          :keepalived_public_ipvs   => ['192.168.0.1', '192.168.0.2'],
          :keepalived_internal_ipvs => ['192.168.1.1', '192.168.1.2']
        )
      end
      it_raises 'a Puppet::Error', /galera_ip should be part of keepalived_public_ipvs or keepalived_internal_ipvs./
    end

    context 'configure OpenStack binding with HTTPS and SSL offloading' do
      before do
        params.merge!(
          :nova_bind_options => ['ssl', 'crt']
        )
      end
      it { should contain_haproxy__listen('nova_api_cluster').with(
        :ipaddress => [params[:vip_public_ip]],
        :ports     => '8774',
        :options   => {
          'mode'           => 'http',
          'option'         => ['tcpka','forwardfor','tcplog','httpchk'],
          'http-check'     => 'expect ! rstatus ^5',
          'balance'        => 'roundrobin',
        },
        :bind_options => ['ssl', 'crt']
      )}
    end

    context 'configure OpenStack binding with HTTP options' do
      before do
        params.merge!(
          :cinder_bind_options => 'something not secure',
        )
      end
      it { should contain_haproxy__listen('cinder_api_cluster').with(
        :ipaddress => [params[:vip_public_ip]],
        :ports     => '8776',
        :options   => {
          'mode'           => 'http',
          'option'         => ['tcpka','forwardfor','tcplog', 'httpchk'],
          'http-check'     => 'expect ! rstatus ^5',
          'balance'        => 'roundrobin',
        },
        :bind_options => ['something not secure']
      )}
    end

    context 'configure OpenStack Horizon with backward compatibility' do
      before do
        params.merge!(
          :horizon_ssl_port => '80'
        )
      end
      it { should contain_haproxy__listen('horizon_cluster').with(
        :ipaddress => [params[:vip_public_ip]],
        :ports     => '80',
        :options   => {
          'mode'           => 'http',
          'http-check'     => 'expect ! rstatus ^5',
          'option'         => ["tcpka", "forwardfor", "tcplog", "httpchk GET  /  \"HTTP/1.0\\r\\nUser-Agent: HAproxy-myhost\""],
          'cookie'         => 'sessionid prefix',
          'balance'        => 'leastconn',
        },
      )}
    end

    context 'configure OpenStack Horizon SSL' do
      before do
        params.merge!(
          :horizon_ssl      => true,
          :horizon_port     => '80',
          :horizon_ssl_port => '443'
        )
      end
      it { should contain_haproxy__listen('horizon_ssl_cluster').with(
        :ipaddress => [params[:vip_public_ip]],
        :ports     => '443',
        :options   => {
          'mode'           => 'tcp',
          'http-check'     => 'expect ! rstatus ^5',
          'option'         => ['tcpka','forwardfor','tcplog',  'ssl-hello-chk'],
          'cookie'         => 'sessionid prefix',
          'balance'        => 'leastconn',
        },
      )}
    end

    context 'configure OpenStack Horizon without SSL' do
      before do
        params.merge!(
          :horizon_port         => '80',
          :horizon_ssl_port     => false,
        )
      end
      it { should contain_haproxy__listen('horizon_cluster').with(
        :ipaddress => [params[:vip_public_ip]],
        :ports     => '80',
        :options   => {
          'mode'           => 'http',
          'http-check'     => 'expect ! rstatus ^5',
          'option'         => ["tcpka", "forwardfor", "tcplog", "httpchk GET  /  \"HTTP/1.0\\r\\nUser-Agent: HAproxy-myhost\""],
          'cookie'         => 'sessionid prefix',
          'balance'        => 'leastconn',
        },
      )}
    end

    context 'configure OpenStack Heat API SSL binding' do
      before do
        params.merge!(
          :heat_api_bind_options => ['ssl', 'crt']
        )
      end
      it { should contain_haproxy__listen('heat_api_cluster').with(
        :ipaddress => [params[:vip_public_ip]],
        :ports     => '8004',
        :options   => {
          'reqadd'         => 'X-Forwarded-Proto:\ https if { ssl_fc }',
          'mode'           => 'http',
          'option'         => ['tcpka','forwardfor','tcplog', 'httpchk'],
          'http-check'     => 'expect ! rstatus ^5',
          'balance'        => 'roundrobin'
        },
        :bind_options => ['ssl', 'crt']
      )}
    end
  end # shared:: openstack loadbalancer

  context 'on Debian platforms' do
    let :facts do
      { :osfamily       => 'Debian',
        :hostname       => 'myhost',
        :concat_basedir => '/var/lib/puppet/concat' }
    end

    it_configures 'openstack loadbalancer'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily       => 'RedHat',
        :hostname       => 'myhost',
        :concat_basedir => '/var/lib/puppet/concat' }
    end

    it_configures 'openstack loadbalancer'
  end

end

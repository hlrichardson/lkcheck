#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k sts=4 sw=4 et
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /kernel/networking/openvswitch/perf_check
#   Author: Rick Alongi <ralongi@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2015 Red Hat, Inc.
#
#   This copyrighted material is made available to anyone wishing
#   to use, modify, copy, or redistribute it subject to the terms
#   and conditions of the GNU General Public License version 2.
#
#   This program is distributed in the hope that it will be
#   useful, but WITHOUT ANY WARRANTY; without even the implied
#   warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#   PURPOSE. See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public
#   License along with this program; if not, write to the Free
#   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
#   Boston, MA 02110-1301, USA.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
dbg_flag=${dbg_flag:-"set +x"}
$dbg_flag

# variables
PACKAGE="kernel"

# include Beaker environment
#. /mnt/tests/kernel/networking/common/include.sh || exit 1
 
# include common install functions
#. /mnt/tests/kernel/networking/common/install.sh || exit 1

# include common networking functions
#. /mnt/tests/kernel/networking/common/network.sh || exit 1
. /mnt/tests/kernel/networking/common/lib/lib_nc_sync.sh || exit 1

#pull down git repo
mkdir /mnt/git_repo
timeout 120s bash -c "until ping -c3 pkgs.devel.redhat.com; do sleep 10; done"
cd /mnt/git_repo && git clone git://pkgs.devel.redhat.com/tests/kernel

# include private common functions
. /mnt/git_repo/kernel/networking/impairment/networking_common.sh || exit 1
. /mnt/git_repo/kernel/networking/impairment/install.sh || exit 1
. /mnt/git_repo/kernel/networking/openvswitch/perf_check/lib_netperf_all.sh || exit 1
. /mnt/git_repo/kernel/networking/openvswitch/perf_check/lib_perf_check.sh || exit 1
. /mnt/git_repo/kernel/networking/openvswitch/lib_config.sh || exit 1

# rhel version
rhel_version=$(cut -f1 -d. /etc/redhat-release | sed 's/[^0-9]//g')

# pointer to netperf package
pkg_netperf=${pkg_netperf:-"http://pkgs.repoforge.org/netperf/netperf-2.6.0-1.el6.rf.x86_64.rpm"}

# check for installation of NetworkManager and install if necessary, enable and start service which was likley stopped by the common functions above
pvt_networkmanager_install

# any NIC driver that you may want to disable for some reason
disabled_nic_driver=${disabled_nic_driver:-""}

# specify interface and MTU to use for test
driver=${driver:-""}
iface=${iface:-""}
if [[ -z $iface ]] && [[ $driver ]]; then
    get-iface-from-driver $driver
elif [[ -z $iface ]] && [[ -z $driver ]]; then
    echo "You must specify either a specific interface OR a specific driver.  Exiting test..."
    exit 1
fi
iface_driver=${iface_driver:-"$(get_iface_driver $iface)"}
link_speed=$(ethtool $iface | grep Speed | awk '{print $2}' | tr -d '[a-z A-Z /]')
mtu=${mtu:-"1500"}
echo "The interface to be used is: $iface."
echo "The driver to be used is: $iface_driver."
echo "The MTU to be used is: $mtu."
echo "The link speed for $iface is: $link_speed Mbps."

vm_name="g0"
vm_list="g0"
intport="intport0"
intport_list="intport0"

# pointer to log files
result_file=${result_file:-"$iface_driver"_mtu$mtu"_ovs_test_result.log"}
selinux_file="selinux_setting.log"

if [ -z "$JOBID" ]; then
	ipaddr=120
else
	ipaddr=$((JOBID % 100 + 20))
fi

if i_am_client; then
    ip4addr=192.168.$((ipaddr + 0)).2
    ip4addr_peer=192.168.$((ipaddr + 0)).4
    ip6addr=2014:$((ipaddr + 0))::2
    ip6addr_peer=2014:$((ipaddr + 0))::4

    ip4addr_vm=192.168.$((ipaddr + 50)).2
    ip4addr_vm_peer=192.168.$((ipaddr + 50)).4
    ip6addr_vm=2015:$((ipaddr + 50))::2
    ip6addr_vm_peer=2015:$((ipaddr + 50))::4

    intport_ip4=192.168.$((ipaddr + 100)).2
    intport_ip4_peer=192.168.$((ipaddr + 100)).4
    intport_ip6=2016:$((ipaddr + 100))::2 
    intport_ip6_peer=2016:$((ipaddr + 100))::4

else
    ip4addr=192.168.$((ipaddr + 0)).4
    ip4addr_peer=192.168.$((ipaddr + 0)).2
    ip6addr=2014:$((ipaddr + 0))::4
    ip6addr_peer=2014:$((ipaddr + 0))::2

    ip4addr_vm=192.168.$((ipaddr + 50)).4
    ip4addr_vm_peer=192.168.$((ipaddr + 50)).2
    ip6addr_vm=2015:$((ipaddr + 50))::4
    ip6addr_vm_peer=2015:$((ipaddr + 50))::2

    intport_ip4=192.168.$((ipaddr + 100)).4
    intport_ip4_peer=192.168.$((ipaddr + 100)).2
    intport_ip6=2016:$((ipaddr + 100))::4
    intport_ip6_peer=2016:$((ipaddr + 100))::2
fi

con_name="static-$iface"
ovsbr="ovsbr0"
intport="intport0"
vxlan_mtu=$(($mtu-58))
vxlan_vlan_mtu=$(($mtu-58))
gre_mtu=$(($mtu-50))
gre_vlan_mtu=$(($mtu-50))
tag="10"
vlan_id="10"

pkg_netperf=${pkg_netperf:-"http://pkgs.repoforge.org/netperf/netperf-2.6.0-1.el6.rf.x86_64.rpm"}
netperf_time=${netperf_time:-"10"}

do_host_netperf=${do_host_netperf:-"do_host_netperf_all"}
do_vm_netperf=${do_vm_netperf:-"do_vm_netperf_all"}
tcp_threshold=${tcp_threshold:-"100"}
udp_threshold=${udp_threshold:-"100"}
tunnel_tcp_threshold=${tunnel_tcp_threshold:-"100"}
tunnel_udp_threshold=${tunnel_udp_threshold:-"100"}

vxlan_tun=${vxlan_tun:-"vxlan1"}
geneve_tun=${geneve_tun:-"geneve1"}
gre_tun=${gre_tun:-"gre1"}

up_knl_vm=${up_knl_vm:-"yes"}

vm_version=${vm_version:-""}

# tests

# Host to Host tests

nic_test()
{
    local use_vm=no
    local result=0
    
    nic_cfg
    set-netperf-threshold $iface
    
    if i_am_client; then
        sync_wait server test_start

        log_header "netperf tests ($netperf_time seconds) - Host to Host, NIC only test" $result_file
        $do_host_netperf $ip4addr,$ip4addr_peer $ip6addr,$ip6addr_peer $result_file,$tcp_threshold,$udp_threshold  "" $netperf_time
        result=$?

        sync_set server test_end         
    else
        sync_set client test_start
        sync_wait client test_end
    fi

    clear_if_config

    return $result
}


ovs_test()
{
    local use_vm=no
    local result=0

    ovs_cfg
    set-netperf-threshold $iface
 
    if i_am_client; then
        sync_wait server test_start

        log_header "netperf tests ($netperf_time seconds) - Host to Host ovs internal port test (without VLAN)" $result_file
        $do_host_netperf $intport_ip4,$intport_ip4_peer $intport_ip6,$intport_ip6_peer $result_file,$tcp_threshold,$udp_threshold  "" $netperf_time
        result=$?

        sync_set server test_end         
    else
        sync_set client test_start
        sync_wait client test_end
    fi

    clear_if_config

    return $result
}

ovs_vlan_test()
{
    local use_vm=no
    local result=0

    ovs_vlan_cfg
    set-netperf-threshold $iface
 
    if i_am_client; then
        sync_wait server test_start

        log_header "netperf tests ($netperf_time seconds) - Host to Host ovs internal port test (with VLAN)" $result_file
        $do_host_netperf $intport_ip4,$intport_ip4_peer $intport_ip6,$intport_ip6_peer $result_file,$tcp_threshold,$udp_threshold  "" $netperf_time
        result=$?

        sync_set server test_end         
    else
        sync_set client test_start
        sync_wait client test_end
    fi

    return $result
}

ovs_vxlan_test()
{
    local use_vm=no
    local use_vxlan="yes"
    local result=0

    ovs_vxlan_cfg
    set-netperf-threshold $iface
    get-tnl-offload-state
 
    if i_am_client; then
        sync_wait server test_start

        log_header "netperf tests ($netperf_time seconds) - Host to Host ovs vxlan test (without VLAN)" $result_file
        $do_host_netperf $intport_ip4,$intport_ip4_peer $intport_ip6,$intport_ip6_peer $result_file,$tunnel_tcp_threshold,$tunnel_udp_threshold  "" $netperf_time
        result=$?

        sync_set server test_end         
    else
        sync_set client test_start
        sync_wait client test_end
    fi

    return $result
}

ovs_vxlan_vlan_test()
{
    local use_vm=no
    local use_vxlan_vlan="yes"
    local result=0

    ovs_vxlan_vlan_cfg
    set-netperf-threshold $iface
    get-tnl-offload-state
 
    if i_am_client; then
        sync_wait server test_start

        log_header "netperf tests ($netperf_time seconds) - Host to Host ovs vxlan test (with VLAN)" $result_file
        $do_host_netperf $intport_ip4,$intport_ip4_peer $intport_ip6,$intport_ip6_peer $result_file,$tunnel_tcp_threshold,$tunnel_udp_threshold  "" $netperf_time
        result=$?

        sync_set server test_end         
    else
        sync_set client test_start
        sync_wait client test_end
    fi

    return $result
}

ovs_geneve_test()
{
    local use_vm=no
    local use_vxlan="yes"
    local result=0

    ovs_geneve_cfg
    set-netperf-threshold $iface
    get-tnl-offload-state
 
    if i_am_client; then
        sync_wait server test_start

        log_header "netperf tests ($netperf_time seconds) - Host to Host ovs Geneve test (without VLAN)" $result_file
        $do_host_netperf $intport_ip4,$intport_ip4_peer $intport_ip6,$intport_ip6_peer $result_file,$tunnel_tcp_threshold,$tunnel_udp_threshold  "" $netperf_time
        result=$?

        sync_set server test_end         
    else
        sync_set client test_start
        sync_wait client test_end
    fi

    return $result
}

ovs_geneve_vlan_test()
{
    local use_vm=no
    local use_vxlan_vlan="yes"
    local result=0

    ovs_geneve_vlan_cfg
    set-netperf-threshold $iface
    get-tnl-offload-state
 
    if i_am_client; then
        sync_wait server test_start

        log_header "netperf tests ($netperf_time seconds) - Host to Host ovs Geneve test (with VLAN)" $result_file
        $do_host_netperf $intport_ip4,$intport_ip4_peer $intport_ip6,$intport_ip6_peer $result_file,$tunnel_tcp_threshold,$tunnel_udp_threshold  "" $netperf_time
        result=$?

        sync_set server test_end         
    else
        sync_set client test_start
        sync_wait client test_end
    fi

    return $result
}

ovs_gre_test()
{
    local use_vm=no
    local use_gre="yes"
    local result=0
 
    ovs_gre_cfg
    set-netperf-threshold $iface
    get-tnl-offload-state
 
    if i_am_client; then
        sync_wait server test_start

        log_header "netperf tests ($netperf_time seconds) - Host to Host ovs gre test (without VLAN)" $result_file
        $do_host_netperf $intport_ip4,$intport_ip4_peer $intport_ip6,$intport_ip6_peer $result_file,$tunnel_tcp_threshold,$tunnel_udp_threshold  "" $netperf_time
        result=$?

        sync_set server test_end         
    else
        sync_set client test_start
        sync_wait client test_end
    fi

    return $result
}

ovs_gre_vlan_test()
{
    local use_vm=no
    local use_gre_vlan="yes"
    local result=0
 
    ovs_gre_vlan_cfg
    set-netperf-threshold $iface
    get-tnl-offload-state
 
    if i_am_client; then
        sync_wait server test_start

        log_header "netperf tests ($netperf_time seconds) - Host to Host ovs gre test (with VLAN)" $result_file
        $do_host_netperf $intport_ip4,$intport_ip4_peer $intport_ip6,$intport_ip6_peer $result_file,$tunnel_tcp_threshold,$tunnel_udp_threshold  "" $netperf_time
        result=$?

        sync_set server test_end         
    else
        sync_set client test_start
        sync_wait client test_end
    fi

    return $result
}

# VM to VM tests

ovs_vm_nic_test()
{
    local use_vm=yes
    local result=0

    ovs_cfg
    set-netperf-threshold $iface
 
    if i_am_client; then
        sync_wait server test_start

        log_header "netperf tests ($netperf_time seconds) - VM to VM ovs nic test (without VLAN)" $result_file
        $do_vm_netperf $vm_name $ip4addr_vm,$ip4addr_vm_peer $ip6addr_vm,$ip6addr_vm_peer $result_file,$tcp_threshold,$udp_threshold  "" $netperf_time
        result=$?

        sync_set server test_end         
    else
        sync_set client test_start
        sync_wait client test_end
    fi

    return $result
}

ovs_vm_nic_vlan_test()
{
    local use_vm=yes
    local result=0

    ovs_vlan_cfg
    set-netperf-threshold $iface
 
    if i_am_client; then
        sync_wait server test_start

        log_header "netperf tests ($netperf_time seconds) - VM to VM ovs nic test (with VLAN)" $result_file
        $do_vm_netperf $vm_name $ip4addr_vm,$ip4addr_vm_peer $ip6addr_vm,$ip6addr_vm_peer $result_file,$tcp_threshold,$udp_threshold  "" $netperf_time
        result=$?

        sync_set server test_end         
    else
        sync_set client test_start
        sync_wait client test_end
    fi

    return $result
}

ovs_vm_vxlan_test()
{
    local use_vm=yes
    local use_vxlan="yes"
    local result=0

    ovs_vxlan_cfg
    set-netperf-threshold $iface
    get-tnl-offload-state
 
    if i_am_client; then
        sync_wait server test_start

        log_header "netperf tests ($netperf_time seconds) - VM to VM ovs vxlan test (without VLAN)" $result_file
        $do_vm_netperf $vm_name $ip4addr_vm,$ip4addr_vm_peer $ip6addr_vm,$ip6addr_vm_peer $result_file,$tunnel_tcp_threshold,$tunnel_udp_threshold  "" $netperf_time
        result=$?

        sync_set server test_end         
    else
        sync_set client test_start
        sync_wait client test_end
    fi

    return $result
}

ovs_vm_vxlan_vlan_test()
{
    local use_vm=yes
    local use_vxlan_vlan="yes"
    local result=0

    ovs_vxlan_vlan_cfg
    set-netperf-threshold $iface
    get-tnl-offload-state
 
    if i_am_client; then
        sync_wait server test_start

        log_header "netperf tests ($netperf_time seconds) - VM to VM ovs vxlan test (with VLAN)" $result_file
        $do_vm_netperf $vm_name $ip4addr_vm,$ip4addr_vm_peer $ip6addr_vm,$ip6addr_vm_peer $result_file,$tunnel_tcp_threshold,$tunnel_udp_threshold  "" $netperf_time
        result=$?

        sync_set server test_end         
    else
        sync_set client test_start
        sync_wait client test_end
    fi

    return $result
}

ovs_vm_geneve_test()
{
    local use_vm=yes
    local use_vxlan="yes"
    local result=0

    ovs_geneve_cfg
    set-netperf-threshold $iface
    get-tnl-offload-state
 
    if i_am_client; then
        sync_wait server test_start

        log_header "netperf tests ($netperf_time seconds) - VM to VM ovs Geneve test (without VLAN)" $result_file
        $do_vm_netperf $vm_name $ip4addr_vm,$ip4addr_vm_peer $ip6addr_vm,$ip6addr_vm_peer $result_file,$tunnel_tcp_threshold,$tunnel_udp_threshold  "" $netperf_time
        result=$?

        sync_set server test_end         
    else
        sync_set client test_start
        sync_wait client test_end
    fi

    return $result
}

ovs_vm_geneve_vlan_test()
{
    local use_vm=yes
    local use_vxlan_vlan="yes"
    local result=0

    ovs_geneve_vlan_cfg
    set-netperf-threshold $iface
    get-tnl-offload-state
 
    if i_am_client; then
        sync_wait server test_start

        log_header "netperf tests ($netperf_time seconds) - VM to VM ovs Geneve test (with VLAN)" $result_file
        $do_vm_netperf $vm_name $ip4addr_vm,$ip4addr_vm_peer $ip6addr_vm,$ip6addr_vm_peer $result_file,$tunnel_tcp_threshold,$tunnel_udp_threshold  "" $netperf_time
        result=$?

        sync_set server test_end         
    else
        sync_set client test_start
        sync_wait client test_end
    fi

    return $result
}

ovs_vm_gre_test()
{
    local use_vm=yes
    local use_gre="yes"
    local result=0

    ovs_gre_cfg
    set-netperf-threshold $iface
    get-tnl-offload-state
 
    if i_am_client; then
        sync_wait server test_start

        log_header "netperf tests ($netperf_time seconds) - VM to VM ovs gre test (without VLAN)" $result_file
        $do_vm_netperf $vm_name $ip4addr_vm,$ip4addr_vm_peer $ip6addr_vm,$ip6addr_vm_peer $result_file,$tunnel_tcp_threshold,$tunnel_udp_threshold  "" $netperf_time
        result=$?

        sync_set server test_end         
    else
        sync_set client test_start
        sync_wait client test_end
    fi

    return $result
}

ovs_vm_gre_vlan_test()
{
    local use_vm=yes
    local use_gre_vlan="yes"
    local result=0

    ovs_gre_vlan_cfg
    set-netperf-threshold $iface
    get-tnl-offload-state
    
    if i_am_client; then
        sync_wait server test_start

        log_header "netperf tests ($netperf_time seconds) - VM to VM ovs gre test (with VLAN)" $result_file
        $do_vm_netperf $vm_name $ip4addr_vm,$ip4addr_vm_peer $ip6addr_vm,$ip6addr_vm_peer $result_file,$tunnel_tcp_threshold,$tunnel_udp_threshold  "" $netperf_time
        result=$?

        sync_set server test_end         
    else
        sync_set client test_start
        sync_wait client test_end
    fi

    return $result
}

# function to check logs for basic problems after each test
check_logs()
{
        local result=0

        if egrep -ir '/oops/|segmentation|lockup|kernel panic' /var/log; then
            return 1
        fi

        if i_am_client; then
                rhts_submit_log -l $result_file
        fi

        return $result
}

# main

rlJournalStart
if [ -z "$JOBID" ]; then
        echo "Variable jobid not set! Assume developer mode."
        CLIENTS="netqe13.knqe.lab.eng.bos.redhat.com"
        SERVERS="netqe14.knqe.lab.eng.bos.redhat.com"
fi

    rlPhaseStartSetup
        # clean up overall environment
        rlRun "cleanup_env"

        # install required packages
        rlRun "do_install"
        
        # finish setting up environment    
        rlRun "configure_env"
        
        kernel_ver=$(uname -r)
        ovs_ver=$(ovs-vsctl show | grep "ovs_version" | awk '{print $2}' | tr -d '["]')
        echo "Kernel version: $kernel_ver"
        echo "OVS version: $ovs_ver"
        if i_am_client; then
            echo "Kernel version: $kernel_ver" >> $result_file
            echo "OVS version: $ovs_ver" >> $result_file
            echo "Interface: "$iface, "Driver: $iface_driver", "Link speed: $link_speed Mbps", "MTU: $mtu"  >> $result_file
            echo "Client : $CLIENTS" >> $result_file
            echo "Server : $SERVERS" >> $result_file
            echo ""
        fi
        echo "SELinux setting: $(getenforce)" >> $selinux_file
    rlPhaseEnd
    
if [ -z "$OVS_TOPO" ] || echo $OVS_TOPO | grep -q -E "(ovs_all|ovs_nic\b)"; then
    rlPhaseStartTest "Run OVS host to host (NIC only) tests"
        rlRun "nic_test"
	    rlRun "check_logs"
    rlPhaseEnd
fi

if [ -z "$OVS_TOPO" ] || echo $OVS_TOPO | grep -q -E "(ovs_all|ovs_no_vlan\b)"; then
    rlPhaseStartTest "Run OVS internal port host to host tests (no VLAN)"
        rlRun "ovs_test"
	    rlRun "check_logs"
    rlPhaseEnd
fi

if [ -z "$OVS_TOPO" ] || echo $OVS_TOPO | grep -q -E "(ovs_all|ovs_vlan\b)"; then
    rlPhaseStartTest "Run OVS internal port host to host tests (VLAN)"
        rlRun "ovs_vlan_test"
	    rlRun "check_logs"
    rlPhaseEnd
fi

if [ -z "$OVS_TOPO" ] || echo $OVS_TOPO | grep -q -E "(ovs_all|ovs_vxlan\b)"; then
    rlPhaseStartTest "Run OVS VXLAN tunnel host to host tests (no VLAN)"
        rlRun "ovs_vxlan_test"
	    rlRun "check_logs"
    rlPhaseEnd
fi

if [ -z "$OVS_TOPO" ] || echo $OVS_TOPO | grep -q -E "(ovs_all|ovs_vxlan_vlan\b)"; then
    rlPhaseStartTest "Run OVS VXLAN tunnel host to host tests (VLAN)"
        rlRun "ovs_vxlan_vlan_test"
	    rlRun "check_logs"
    rlPhaseEnd
fi

if [ -z "$OVS_TOPO" ] || echo $OVS_TOPO | grep -q -E "(ovs_all|ovs_geneve\b)" && [[ $(echo $ovs_ver | awk -F "." '{print $1$2$3}') -ge 240 ]]; then
    rlPhaseStartTest "Run OVS Geneve tunnel host to host tests (no VLAN)"
        rlRun "ovs_geneve_test"
	    rlRun "check_logs"
    rlPhaseEnd
fi

if [ -z "$OVS_TOPO" ] || echo $OVS_TOPO | grep -q -E "(ovs_all|ovs_geneve_vlan\b)" && [[ $(echo $ovs_ver | awk -F "." '{print $1$2$3}') -ge 240 ]]; then    
	rlPhaseStartTest "Run OVS Geneve tunnel host to host tests (VLAN)"
        rlRun "ovs_geneve_vlan_test"
	    rlRun "check_logs"
	rlPhaseEnd
fi

if [ -z "$OVS_TOPO" ] || echo $OVS_TOPO | grep -q -E "(ovs_all|ovs_gre\b)"; then
    rlPhaseStartTest "Run OVS GRE tunnel host to host tests (no VLAN)"
        rlRun "ovs_gre_test"
	    rlRun "check_logs"
    rlPhaseEnd
fi

if [ -z "$OVS_TOPO" ] || echo $OVS_TOPO | grep -q -E "(ovs_all|ovs_gre_vlan\b)"; then
    rlPhaseStartTest "Run OVS GRE tunnel host to host tests (VLAN)"
        rlRun "ovs_gre_vlan_test"
	    rlRun "check_logs"
    rlPhaseEnd
fi

if [ -z "$OVS_TOPO" ] || echo $OVS_TOPO | grep -q -E "(ovs_all|ovs_vm\b)"; then
    rlPhaseStartTest "Run OVS vm to vm nic tests (no VLAN)"
        rlRun "ovs_vm_nic_test"
	    rlRun "check_logs"
    rlPhaseEnd
fi

if [ -z "$OVS_TOPO" ] || echo $OVS_TOPO | grep -q -E "(ovs_all|ovs_vm_vlan\b)"; then
    rlPhaseStartTest "Run OVS vm to vm nic tests (VLAN)"
        rlRun "ovs_vm_nic_vlan_test"
	    rlRun "check_logs"
    rlPhaseEnd
fi

if [ -z "$OVS_TOPO" ] || echo $OVS_TOPO | grep -q -E "(ovs_all|ovs_vm_vxlan\b)"; then
    rlPhaseStartTest "Run OVS vxlan vm to vm tests (no VLAN)"
        rlRun "ovs_vm_vxlan_test"
	    rlRun "check_logs"
    rlPhaseEnd
fi

if [ -z "$OVS_TOPO" ] || echo $OVS_TOPO | grep -q -E "(ovs_all|ovs_vm_vxlan_vlan\b)"; then
    rlPhaseStartTest "Run OVS vxlan vm to vm tests (VLAN)"
        rlRun "ovs_vm_vxlan_vlan_test"
	    rlRun "check_logs"
    rlPhaseEnd
fi

if [ -z "$OVS_TOPO" ] || echo $OVS_TOPO | grep -q -E "(ovs_all|ovs_vm_geneve\b)" && [[ $(echo $ovs_ver | awk -F "." '{print $1$2$3}') -ge 240 ]]; then
    rlPhaseStartTest "Run OVS Geneve vm to vm tests (no VLAN)"
        rlRun "ovs_vm_geneve_test"
	    rlRun "check_logs"
    rlPhaseEnd
fi

if [ -z "$OVS_TOPO" ] || echo $OVS_TOPO | grep -q -E "(ovs_all|ovs_vm_geneve_vlan\b)" && [[ $(echo $ovs_ver | awk -F "." '{print $1$2$3}') -ge 240 ]]; then
    rlPhaseStartTest "Run OVS Geneve vm to vm tests (VLAN)"
        rlRun "ovs_vm_geneve_vlan_test"
	    rlRun "check_logs"
    rlPhaseEnd
fi

if [ -z "$OVS_TOPO" ] || echo $OVS_TOPO | grep -q -E "(ovs_all|ovs_vm_gre\b)"; then
    rlPhaseStartTest "Run OVS gre vm to vm tests (no VLAN)"
        rlRun "ovs_vm_gre_test"
	    rlRun "check_logs"
    rlPhaseEnd
fi

if [ -z "$OVS_TOPO" ] || echo $OVS_TOPO | grep -q -E "(ovs_all|ovs_vm_gre_vlan\b)"; then
    rlPhaseStartTest "Run OVS gre vm to vm tests (VLAN)"
        rlRun "ovs_vm_gre_vlan_test"
	    rlRun "check_logs"
    rlPhaseEnd
fi

rlPhaseStartTest "Clean up the overall environment at end of all tests"
    rlRun "cleanup_env"
rlPhaseEnd

rhts_submit_log -l $selinux_file

if i_am_client; then
    rhts_submit_log -l $result_file
fi
rlJournalPrintText
rlJournalEnd

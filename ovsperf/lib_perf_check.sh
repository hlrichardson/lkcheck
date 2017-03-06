. /mnt/git_repo/kernel/networking/openvswitch/lib_config.sh || exit 1
. /mnt/git_repo/kernel/networking/impairment/install.sh

# functions for perf_check test

function set-netperf-threshold
{
	set -x
	local func_name="set-netperf-threshold"
	
	function display-usage
	{
		echo "$func_name requires 1 argument (interface)"
		echo "Usage: $func_name <iface>"
		echo "Example: $func_name p2p1"
	}
	
	if [[ $1 == "-h" ]] || [[ $1 == "--help" ]] || [[ $1 == "-?" ]]; then display-usage; return 0; fi
	
	if [[ $# -ne 1 ]]; then display-usage; exit 1; fi
	
	local iface=$1
	local driver=$(ethtool -i $iface | grep driver | awk '{print $2}')
	local iface_speed=$(ethtool $iface | grep Speed | awk '{print $2}' | tr -d '[a-z A-Z /]')
	tnl_offload_state=$(ethtool -k $iface | grep tx-udp_tnl-segmentation | awk '{ print $2 }')	
	
	# set the netperf thhreshold based on scenario
	
	# ixgbe
	if [[ $driver == "ixgbe" ]] && [[ $mtu -eq 1500 ]]; then
		if [[ $(ovs-vsctl show | egrep 'vxlan|gre|geneve') ]] && [[ $iface_speed -eq 10000 ]] && [[ $tnl_offload_state == "off" ]]; then
			tcp_threshold=4000
			udp_threshold=2000
		elif [[ $(ovs-vsctl show | egrep 'vxlan|geneve') ]] && [[ $iface_speed -eq 10000 ]] && [[ $tnl_offload_state == "on" ]]; then
			tcp_threshold=9000
			udp_threshold=2000
		else
			tcp_threshold=9000
			udp_threshold=2000
		fi
	elif [[ $driver == "ixgbe" ]] && [[ $mtu -eq 9000 ]]; then
		if [[ $(ovs-vsctl show | egrep 'vxlan|gre|geneve') ]] && [[ $iface_speed -eq 10000 ]] && [[ $tnl_offload_state == "off" ]]; then
			tcp_threshold=4000
			udp_threshold=2000
		elif [[ $(ovs-vsctl show | egrep 'vxlan|geneve') ]] && [[ $iface_speed -eq 10000 ]] && [[ $tnl_offload_state == "on" ]]; then
			tcp_threshold=9000
			udp_threshold=2000
		else
			tcp_threshold=9000
			udp_threshold=2000
		fi
		
	# i40e
	elif [[ $driver == "i40e" ]] && [[ $mtu -eq 1500 ]]; then
		if [[ $(ovs-vsctl show | egrep 'vxlan|gre|geneve') ]] && [[ $iface_speed -eq 10000 ]] && [[ $tnl_offload_state == "off" ]]; then
			tcp_threshold=4000
			udp_threshold=2000
		elif [[ $(ovs-vsctl show | egrep 'vxlan|geneve') ]] && [[ $iface_speed -eq 10000 ]] && [[ $tnl_offload_state == "on" ]]; then
			tcp_threshold=9000
			udp_threshold=2000
		elif [[ $(ovs-vsctl show | egrep 'vxlan|gre|geneve') ]] && [[ $iface_speed -eq 40000 ]] && [[ $tnl_offload_state == "off" ]]; then
			tcp_threshold=4000
			udp_threshold=2000
		elif [[ $(ovs-vsctl show | egrep 'vxlan|geneve') ]] && [[ $iface_speed -eq 40000 ]] && [[ $tnl_offload_state == "on" ]]; then
			tcp_threshold=18000
			udp_threshold=2000
		elif [[ $iface_speed -eq 10000 ]]; then
			tcp_threshold=9000
			udp_threshold=2000
		elif [[ $iface_speed -eq 40000 ]]; then
			tcp_threshold=18000
			udp_threshold=2000
		fi
	elif [[ $driver == "i40e" ]] && [[ $mtu -eq 9000 ]]; then
		if [[ $(ovs-vsctl show | egrep 'vxlan|gre|geneve') ]] && [[ $iface_speed -eq 10000 ]] && [[ $tnl_offload_state == "off" ]]; then
			tcp_threshold=4000
			udp_threshold=2000
		elif [[ $(ovs-vsctl show | egrep 'vxlan|geneve') ]] && [[ $iface_speed -eq 10000 ]] && [[ $tnl_offload_state == "on" ]]; then
			tcp_threshold=9000
			udp_threshold=2000
		elif [[ $(ovs-vsctl show | egrep 'vxlan|gre|geneve') ]] && [[ $iface_speed -eq 40000 ]] && [[ $tnl_offload_state == "off" ]]; then
			tcp_threshold=4000
			udp_threshold=2000
		elif [[ $(ovs-vsctl show | egrep 'vxlan|geneve') ]] && [[ $iface_speed -eq 40000 ]] && [[ $tnl_offload_state == "on" ]]; then
			tcp_threshold=18000
			udp_threshold=2000
		elif [[ $iface_speed -eq 10000 ]]; then
			tcp_threshold=9000
			udp_threshold=2000
		elif [[ $iface_speed -eq 40000 ]]; then
			tcp_threshold=18000
			udp_threshold=2000
		fi
		
	# bnx2x
	elif [[ $driver == "bnx2x" ]] && [[ $mtu -eq 1500 ]]; then
		if [[ $(ovs-vsctl show | egrep 'vxlan|gre|geneve') ]] && [[ $iface_speed -eq 10000 ]] && [[ $tnl_offload_state == "off" ]]; then
			tcp_threshold=4000
			udp_threshold=2000
		elif [[ $(ovs-vsctl show | egrep 'vxlan|geneve') ]] && [[ $iface_speed -eq 10000 ]] && [[ $tnl_offload_state == "on" ]]; then
			tcp_threshold=9000
			udp_threshold=2000
		elif [[ $(ovs-vsctl show | egrep 'vxlan|gre|geneve') ]] && [[ $iface_speed -eq 40000 ]] && [[ $tnl_offload_state == "off" ]]; then
			tcp_threshold=4000
			udp_threshold=2000
		elif [[ $(ovs-vsctl show | egrep 'vxlan|geneve') ]] && [[ $iface_speed -eq 40000 ]] && [[ $tnl_offload_state == "on" ]]; then
			tcp_threshold=18000
			udp_threshold=2000
		elif [[ $iface_speed -eq 10000 ]]; then
			tcp_threshold=9000
			udp_threshold=2000
		elif [[ $iface_speed -eq 40000 ]]; then
			tcp_threshold=18000
			udp_threshold=2000
		fi
	elif [[ $driver == "bnx2x" ]] && [[ $mtu -eq 9000 ]]; then
		if [[ $(ovs-vsctl show | egrep 'vxlan|gre|geneve') ]] && [[ $iface_speed -eq 10000 ]] && [[ $tnl_offload_state == "off" ]]; then
			tcp_threshold=4000
			udp_threshold=2000
		elif [[ $(ovs-vsctl show | egrep 'vxlan|geneve') ]] && [[ $iface_speed -eq 10000 ]] && [[ $tnl_offload_state == "on" ]]; then
			tcp_threshold=9000
			udp_threshold=2000
		elif [[ $(ovs-vsctl show | egrep 'vxlan|gre|geneve') ]] && [[ $iface_speed -eq 40000 ]] && [[ $tnl_offload_state == "off" ]]; then
			tcp_threshold=4000
			udp_threshold=2000
		elif [[ $(ovs-vsctl show | egrep 'vxlan|geneve') ]] && [[ $iface_speed -eq 40000 ]] && [[ $tnl_offload_state == "on" ]]; then
			tcp_threshold=18000
			udp_threshold=2000
		elif [[ $iface_speed -eq 10000 ]]; then
			tcp_threshold=9000
			udp_threshold=2000
		elif [[ $iface_speed -eq 40000 ]]; then
			tcp_threshold=18000
			udp_threshold=2000
		fi
		
	# be2net
	elif [[ $driver == "be2net" ]] && [[ $mtu -eq 1500 ]]; then
		if [[ $(ovs-vsctl show | egrep 'vxlan|gre|geneve') ]] && [[ $iface_speed -eq 10000 ]] && [[ $tnl_offload_state == "off" ]]; then
			tcp_threshold=4000
			udp_threshold=2000
		elif [[ $(ovs-vsctl show | egrep 'vxlan|geneve') ]] && [[ $iface_speed -eq 10000 ]] && [[ $tnl_offload_state == "on" ]]; then
			tcp_threshold=9000
			udp_threshold=2000
		elif [[ $(ovs-vsctl show | egrep 'vxlan|gre|geneve') ]] && [[ $iface_speed -eq 40000 ]] && [[ $tnl_offload_state == "off" ]]; then
			tcp_threshold=4000
			udp_threshold=2000
		elif [[ $(ovs-vsctl show | egrep 'vxlan|geneve') ]] && [[ $iface_speed -eq 40000 ]] && [[ $tnl_offload_state == "on" ]]; then
			tcp_threshold=18000
			udp_threshold=2000
		elif [[ $iface_speed -eq 10000 ]]; then
			tcp_threshold=9000
			udp_threshold=2000
		elif [[ $iface_speed -eq 40000 ]]; then
			tcp_threshold=18000
			udp_threshold=2000
		fi
	elif [[ $driver == "be2net" ]] && [[ $mtu -eq 9000 ]]; then
		if [[ $(ovs-vsctl show | egrep 'vxlan|gre|geneve') ]] && [[ $iface_speed -eq 10000 ]] && [[ $tnl_offload_state == "off" ]]; then
			tcp_threshold=4000
			udp_threshold=2000
		elif [[ $(ovs-vsctl show | egrep 'vxlan|geneve') ]] && [[ $iface_speed -eq 10000 ]] && [[ $tnl_offload_state == "on" ]]; then
			tcp_threshold=9000
			udp_threshold=2000
		elif [[ $(ovs-vsctl show | egrep 'vxlan|gre|geneve') ]] && [[ $iface_speed -eq 40000 ]] && [[ $tnl_offload_state == "off" ]]; then
			tcp_threshold=4000
			udp_threshold=2000
		elif [[ $(ovs-vsctl show | egrep 'vxlan|geneve') ]] && [[ $iface_speed -eq 40000 ]] && [[ $tnl_offload_state == "on" ]]; then
			tcp_threshold=18000
			udp_threshold=2000
		elif [[ $iface_speed -eq 10000 ]]; then
			tcp_threshold=9000
			udp_threshold=2000
		elif [[ $iface_speed -eq 40000 ]]; then
			tcp_threshold=18000
			udp_threshold=2000
		fi

	# mlx4_en
	elif [[ $driver == "mlx4_en" ]] && [[ $mtu -eq 1500 ]]; then
		if [[ $(ovs-vsctl show | egrep 'vxlan|gre|geneve') ]] && [[ $iface_speed -eq 10000 ]] && [[ $tnl_offload_state == "off" ]]; then
			tcp_threshold=4000
			udp_threshold=2000
		elif [[ $(ovs-vsctl show | egrep 'vxlan|geneve') ]] && [[ $iface_speed -eq 10000 ]] && [[ $tnl_offload_state == "on" ]]; then
			tcp_threshold=9000
			udp_threshold=2000
		elif [[ $(ovs-vsctl show | egrep 'vxlan|gre|geneve') ]] && [[ $iface_speed -eq 40000 ]] && [[ $tnl_offload_state == "off" ]]; then
			tcp_threshold=4000
			udp_threshold=2000
		elif [[ $(ovs-vsctl show | egrep 'vxlan|geneve') ]] && [[ $iface_speed -eq 40000 ]] && [[ $tnl_offload_state == "on" ]]; then
			tcp_threshold=18000
			udp_threshold=2000
		elif [[ $iface_speed -eq 10000 ]]; then
			tcp_threshold=9000
			udp_threshold=2000
		elif [[ $iface_speed -eq 40000 ]]; then
			tcp_threshold=18000
			udp_threshold=2000
		fi
	elif [[ $driver == "mlx4_en" ]] && [[ $mtu -eq 9000 ]]; then
		if [[ $(ovs-vsctl show | egrep 'vxlan|gre|geneve') ]] && [[ $iface_speed -eq 10000 ]] && [[ $tnl_offload_state == "off" ]]; then
			tcp_threshold=4000
			udp_threshold=2000
		elif [[ $(ovs-vsctl show | egrep 'vxlan|geneve') ]] && [[ $iface_speed -eq 10000 ]] && [[ $tnl_offload_state == "on" ]]; then
			tcp_threshold=9000
			udp_threshold=2000
		elif [[ $(ovs-vsctl show | egrep 'vxlan|gre|geneve') ]] && [[ $iface_speed -eq 40000 ]] && [[ $tnl_offload_state == "off" ]]; then
			tcp_threshold=4000
			udp_threshold=2000
		elif [[ $(ovs-vsctl show | egrep 'vxlan|geneve') ]] && [[ $iface_speed -eq 40000 ]] && [[ $tnl_offload_state == "on" ]]; then
			tcp_threshold=18000
			udp_threshold=2000
		elif [[ $iface_speed -eq 10000 ]]; then
			tcp_threshold=9000
			udp_threshold=2000
		elif [[ $iface_speed -eq 40000 ]]; then
			tcp_threshold=18000
			udp_threshold=2000
		fi
	
	# cxgb4
	elif [[ $driver == "cxgb4" ]] && [[ $mtu -eq 1500 ]]; then
		if [[ $(ovs-vsctl show | egrep 'vxlan|gre|geneve') ]] && [[ $iface_speed -eq 10000 ]] && [[ $tnl_offload_state == "off" ]]; then
			tcp_threshold=4000
			udp_threshold=2000
		elif [[ $(ovs-vsctl show | egrep 'vxlan|geneve') ]] && [[ $iface_speed -eq 10000 ]] && [[ $tnl_offload_state == "on" ]]; then
			tcp_threshold=9000
			udp_threshold=2000
		elif [[ $(ovs-vsctl show | egrep 'vxlan|gre|geneve') ]] && [[ $iface_speed -eq 40000 ]] && [[ $tnl_offload_state == "off" ]]; then
			tcp_threshold=4000
			udp_threshold=2000
		elif [[ $(ovs-vsctl show | egrep 'vxlan|geneve') ]] && [[ $iface_speed -eq 40000 ]] && [[ $tnl_offload_state == "on" ]]; then
			tcp_threshold=18000
			udp_threshold=2000
		elif [[ $iface_speed -eq 10000 ]]; then
			tcp_threshold=9000
			udp_threshold=2000
		elif [[ $iface_speed -eq 40000 ]]; then
			tcp_threshold=18000
			udp_threshold=2000
		fi
	elif [[ $driver == "cxgb4" ]] && [[ $mtu -eq 9000 ]]; then
		if [[ $(ovs-vsctl show | egrep 'vxlan|gre|geneve') ]] && [[ $iface_speed -eq 10000 ]] && [[ $tnl_offload_state == "off" ]]; then
			tcp_threshold=4000
			udp_threshold=2000
		elif [[ $(ovs-vsctl show | egrep 'vxlan|geneve') ]] && [[ $iface_speed -eq 10000 ]] && [[ $tnl_offload_state == "on" ]]; then
			tcp_threshold=9000
			udp_threshold=2000
		elif [[ $(ovs-vsctl show | egrep 'vxlan|gre|geneve') ]] && [[ $iface_speed -eq 40000 ]] && [[ $tnl_offload_state == "off" ]]; then
			tcp_threshold=4000
			udp_threshold=2000
		elif [[ $(ovs-vsctl show | egrep 'vxlan|geneve') ]] && [[ $iface_speed -eq 40000 ]] && [[ $tnl_offload_state == "on" ]]; then
			tcp_threshold=18000
			udp_threshold=2000
		elif [[ $iface_speed -eq 10000 ]]; then
			tcp_threshold=9000
			udp_threshold=2000
		elif [[ $iface_speed -eq 40000 ]]; then
			tcp_threshold=18000
			udp_threshold=2000
		fi
	else
		# set the iface_buffer based on config, link speed, etc. if one of the drivers above is not being used
		if [[ $(ovs-vsctl show | egrep 'vxlan|gre|geneve') ]] && [[ $iface_speed -eq 10000 ]] && [[ $tnl_offload_state == "off" ]]; then
			float=0.45
		elif [[ $(ovs-vsctl show | egrep 'vxlan|geneve') ]] && [[ $iface_speed -eq 10000 ]] && [[ $tnl_offload_state == "on" ]]; then
			float=0.85
		elif [[ $(ovs-vsctl show | egrep 'vxlan|gre|geneve') ]] && [[ $iface_speed -eq 40000 ]] && [[ $tnl_offload_state == "off" ]]; then
			float=0.25
		elif [[ $(ovs-vsctl show | egrep 'vxlan|geneve') ]] && [[ $iface_speed -eq 40000 ]] && [[ $tnl_offload_state == "on" ]]; then
			float=0.45
		elif [[ $iface_speed -eq 10000 ]]; then
			float=0.85
		elif [[ $iface_speed -eq 40000 ]]; then
			float=0.45
		fi

		local iface_buffer=$(echo "($float)" | bc)
		tcp_threshold=$(echo "$iface_speed*$iface_buffer" | bc | awk '{printf "%.0f\n", $1}')
		udp_threshold=2000
	fi
	
	export tcp_result_criteria=$tcp_threshold
	export udp_result_criteria=$udp_threshold
	echo "The driver for $iface is: $driver"
	echo "The link speed of $iface is: $iface_speed Mbps"
	echo "Tunnel offload is: $tnl_offload"
	echo "The configured netperf tcp_threshold is: $tcp_threshold Mbps"
	echo "The configured netperf udp_threshold is: $udp_threshold Mbps"
	
	set +x
}

function get-tnl-offload-state
{
	sleep 10
	tnl_offload_state=$(ethtool -k $iface | grep tx-udp_tnl-segmentation | awk '{ print $2 }')
	echo "vxlan offload: $tnl_offload_state"
}


netperf_start()
{
	pgrep netserver
	if [[ $? != 0 ]]; then
		pkill netserver; sleep 2; netserver
	else
		echo "netserver is running."
	fi
}

vm_netperf_start()
{
    local vm_name=$1
	vmsh run_cmd $vm_name "pgrep netserver" > pgrep_nserv.txt
	dos2unix -f pgrep_nserv.txt
	r=$(grep -A1 'echo $?' pgrep_nserv.txt | awk '{ getline; print }')	
	if [[ $r != 0 ]]; then
		vmsh run_cmd $vm_name "pkill netserver; sleep 2; netserver"
		rm -f pgrep_nserv.txt
	else
        echo "netserver is running."
		rm -f pgrep_nserv.txt
	fi
}

function set-iface-ip
{
	local iface=$1
	ip addr flush dev $iface
	ip link set dev $iface up
	ip link set dev $iface mtu $mtu
	ip addr add dev $iface $ip4addr/24
	ip addr add dev $iface $ip6addr/64
	sleep 5
}
	

function prep-vm
{
    local vm_name=$1
    start-vm $vm_name
    get-iface-vm $vm_name
    vmsh run_cmd $vm_name "ip link set dev $iface_vm mtu $mtu"
    flush-iptables-vm $vm_name
    vm_netperf_start $vm_name
}

function refresh-vms
{
    for i in $intport_list; do ovs-vsctl --if-exists del-port $i; done
	for i in $vm_list; do virsh shutdown $i; done
	sleep 10
	for i in $vm_list; do virsh start $i; done
	sleep 30
	for i in $vm_list; do vmsh run_cmd $i "pkill netserver; sleep 2; netserver"; done
	get-vnets $ovsbr
}

function get-iface-info
{
    local iface=$1
    ip a | grep -A4 $iface
    echo -e
    ip r
    echo -e
    ip -6 r
    echo -e
    ovs-vsctl show
    echo -e
}

get_nic_driver_info()
{
    echo "NIC driver information for $iface: "
    echo -e
    ethtool -i $iface
    echo -e
    ethtool $iface
    echo -e
    ethtool -k $iface
    echo -e
}

vxlan_offload_check_enable()
{
    local tnl_offload=$(ethtool -k $iface | grep tx-udp_tnl-segmentation | awk '{ print $2 }')
    if [[ $rhel_version -ge 7 && $tnl_offload == off ]]; then
        #echo "THERE IS A PROBLEM WITH THE $driver VXLAN OFFLOAD SETTING!  IT IS NOT ENABLED!  RELOADING $driver DRIVER TO ATTEMPT TO ENABLE VXLAN OFFLOAD..."
        #rmmod ocrdma || true
        #rmmod $iface_driver; sleep 3; modprobe $iface_driver; sleep 3
        #ip link set dev $iface up
        #echo "The $driver driver has been reloaded.  tx-udp_tnl-segmentation is now set to: $tnl_offload"
        echo "THERE IS A PROBLEM WITH THE $iface_driver VXLAN OFFLOAD SETTING!  IT IS NOT ENABLED!  ATTEMPTING TO ENABLE VXLAN OFFLOAD on $iface USING ETHTOOL..."
        ethtool -K $iface tx-udp_tnl-segmentation on || true
        sleep 3
        echo "The ethtool command was executed on $iface in an attempt to enable vxlan offload.  tx-udp_tnl-segmentation is now set to: $tnl_offload"
    else 
        echo "tx-udp_tnl-segmentation is set to: $tnl_offload"
    fi
}

# functions to set config for various scenarios under test

nic_cfg()
{
	ovs-vsctl list bridge | grep name | awk '{system("ovs-vsctl --if-exist del-br "$3)}'
	sleep 10
	set-iface-ip $iface
	sleep 10
	
	echo "nic_cfg was run.  Here is the interface information:"
	get-iface-info $iface
}

ovs_cfg()
{
    create-ovsbr-vsctl $ovsbr
    create-ovsbr-port-vsctl -phy $ovsbr $iface
    create-ovsbr-port-vsctl -internal $ovsbr $intport
    ip addr flush dev $intport
    ip addr add $intport_ip4/24 dev $intport
    ip -6 addr add $intport_ip6/64 dev $intport
    
    if [[ "$use_vm" == "yes" ]]; then
		refresh-vms
		for i in $vnets; do ip link set dev $i mtu $mtu; done		
		for i in $vm_list; do prep-vm $i; vmsh run_cmd $i "ip link set dev $iface_vm mtu $mtu"; done
	fi
	
	echo "ovs_cfg was run.  Here is the interface information:"
	get-iface-info $iface
	get-iface-info $intport
}

ovs_vlan_cfg()
{
    ovs_cfg
    ovs-vsctl set port $intport tag=$vlan_id
    
    if [[ "$use_vm" == "yes" ]]; then
        for i in $vnets; do ovs-vsctl set port $i tag=$vlan_id; done
	fi
	
	echo "ovs_vlan_cfg was run.  Here is the interface information:"
	get-iface-info $iface
	get-iface-info $intport
}

ovs_vxlan_cfg()
{
    local use_vxlan="yes"   

    # reload be2net driver to try and work around vxlan offload problem
    if [[ $iface_driver == "be2net" ]] && [[ $rhel_version -ge 7 ]]; then reload_nic_driver $iface_driver; fi
    
    set-iface-ip $iface
    create-ovsbr-vsctl $ovsbr
    create-ovsbr-port-vsctl -vxlan $ovsbr $vxlan_tun $ip4addr_peer
    create-ovsbr-port-vsctl -internal $ovsbr $intport
    ip addr flush dev $intport; ip link set dev $intport mtu $vxlan_mtu    
    ip addr add $intport_ip4/24 dev $intport; ip -6 addr add $intport_ip6/64 dev $intport   
    
    if [[ "$use_vm" == "yes" ]]; then
		refresh-vms
		for i in $vnets; do ip link set dev $i mtu $vxlan_mtu; done		
		for i in $vm_list; do prep-vm $i; vmsh run_cmd $i "ip link set dev $iface_vm mtu $vxlan_mtu"; done
	fi
	
	echo "ovs_vxlan_cfg was run.  Here is the interface information:"
	get-iface-info $iface
	get-iface-info $intport
    if i_am_client; then sleep 60; ping -c3 $ip4addr_peer; fi
}
    
ovs_vxlan_vlan_cfg()
{
    local use_vxlan_vlan="yes"
    ovs_vxlan_cfg
    ovs-vsctl set port $intport tag=$vlan_id
    
    if [[ "$use_vm" == "yes" ]]; then
        for i in $vnets; do ovs-vsctl set port $i tag=$vlan_id; done
	fi
	echo "ovs_vxlan_vlan_cfg was run.  Here is the interface information:"
	get-iface-info $iface
	get-iface-info $intport
}

ovs_geneve_cfg()
{
    local use_vxlan="yes"   

    # reload be2net driver to try and work around vxlan offload problem
    if [[ $iface_driver == "be2net" ]]; then reload_nic_driver $iface_driver; fi
    
    set-iface-ip $iface
    create-ovsbr-vsctl $ovsbr
    create-ovsbr-port-vsctl -geneve $ovsbr $geneve_tun $ip4addr_peer
    create-ovsbr-port-vsctl -internal $ovsbr $intport
    ip addr flush dev $intport; ip link set dev $intport mtu $vxlan_mtu    
    ip addr add $intport_ip4/24 dev $intport; ip -6 addr add $intport_ip6/64 dev $intport   
    
    if [[ "$use_vm" == "yes" ]]; then
		refresh-vms
		for i in $vnets; do ip link set dev $i mtu $vxlan_mtu; done		
		for i in $vm_list; do prep-vm $i; vmsh run_cmd $i "ip link set dev $iface_vm mtu $vxlan_mtu"; done
	fi
	echo "ovs_geneve_cfg was run.  Here is the interface information:"
	get-iface-info $iface
	get-iface-info $intport
    if i_am_client; then sleep 60; ping -c3 $ip4addr_peer; fi
}
    
ovs_geneve_vlan_cfg()
{
    local use_vxlan_vlan="yes"
    ovs_geneve_cfg
    ovs-vsctl set port $intport tag=$vlan_id
    
    if [[ "$use_vm" == "yes" ]]; then
         for i in $vnets; do ovs-vsctl set port $i tag=$vlan_id; done
	fi
	get-iface-info $iface
	get-iface-info $intport
}

ovs_gre_cfg()
{
    local use_gre="yes"   

	set-iface-ip $iface
    create-ovsbr-vsctl $ovsbr
    create-ovsbr-port-vsctl -gre $ovsbr $gre_tun $ip4addr_peer
    create-ovsbr-port-vsctl -internal $ovsbr $intport
    ip addr flush dev $intport; ip link set dev $intport mtu $gre_mtu    
    ip addr add $intport_ip4/24 dev $intport; ip -6 addr add $intport_ip6/64 dev $intport   
    
    if [[ "$use_vm" == "yes" ]]; then
		refresh-vms
		for i in $vnets; do ip link set dev $i mtu $gre_mtu; done		
		for i in $vm_list; do prep-vm $i; vmsh run_cmd $i "ip link set dev $iface_vm mtu $gre_mtu"; done
	fi
	
	echo "ovs_gre_cfg was run.  Here is the interface information:"
	get-iface-info $iface
	get-iface-info $intport
    if i_am_client; then sleep 60; ping -c3 $ip4addr_peer; fi
}
    
ovs_gre_vlan_cfg()
{
    local use_gre_vlan="yes"
    ovs_gre_cfg
    ovs-vsctl set port $intport tag=$vlan_id
    
    if [[ "$use_vm" == "yes" ]]; then
        for i in $vnets; do ovs-vsctl set port $i tag=$vlan_id; done
	fi
	
	echo "ovs_gre_vlan_cfg was run.  Here is the interface information:"
	get-iface-info $iface
	get-iface-info $intport
}

# function to clean up entire environment before and after overall test run
cleanup_env()
{
	# echo "remove any bridge if exist"
	brctl show | sed -n 2~1p | awk '/^[[:alpha:]]/ { system("ip link set "$1" down; brctl delbr "$1) }'

	# echo "remove any ovs bridge if exist"
	ovs-vsctl list bridge | grep name | awk '{system("ovs-vsctl --if-exist del-br "$3)}'

	# echo "remove any vxlan if exist"
	ip -d link show | grep "\bvxlan\b" -B 2 | sed -n 1~3p | awk '{gsub(":",""); system ("ip link del "$2)}'

	# echo "remove any gre if exist"
	ip -d link show|grep "\bgretap\b" -B 2 | sed -n 1~3p | awk '($2 ~ /[[:alnum:]]+@[[:alnum:]]+/) {split($2,gre,"@"); system("ip link del "gre[1])}'

	# echo "remove any VM if exist"
	virsh list --all | sed -n 3~1p | awk '/[[:alpha:]]+/ { if ($3 == "running") { system("virsh shutdown "$2); sleep 2; system("virsh destroy "$2) }; system("virsh undefine --managed-save --snapshots-metadata --remove-all-storage "$2) }'
	# echo "remove any vnet definition if exist"
	virsh net-list --all | sed -n 3~1p | awk '/[[:alnum:]]+/ { system("virsh net-destroy "$1); sleep 2; system("virsh net-undefine "$1) }'

	#echo "remove any netns if exist"
	ip netns list | awk '{system("ip netns del "$1)}'

	#echo "delete the static connection via nmcli"
    nmcli con show | grep $con_name
    if [[ $? == 0 ]]; then nmcli con del $con_name; fi    
}

# function to clear out interface configt between individual tests    
clear_if_config()
{
    ip address flush dev $iface
    ip link set dev $iface down
    ip link set dev $iface mtu 1500
    ovs-vsctl --if-exists del-br $ovsbr
    if [[ "$use_vm" == "yes" ]]; then
        ip link set dev $vnet mtu 1500
        vmsh run_cmd $vm "ip link set mtu 1500 dev $iface_vm"
    fi
    sleep 10
}    
    
#----------------------------------------------------------

# install necessary packages.  functions below are pulled from kernel/networking/impairment/install.sh
do_install()
{
    # epel repo
    pvt_epel_install

    # netperf
    pvt_netperf_install
    pkill netserver; sleep 2; netserver

    # sshpass
    pvt_sshpass_install

    # dos2unix
    yum -y install dos2unix

    # httpd
    pvt_httpd_install

    # ovs
    pvt_ovs_install
    ovs_ver=$(ovs-vsctl show | grep ovs_version | awk -F : '{ print $2 }' | tr -d '"' | tr -d " ")

    #virtualization
    pvt_virt_install

    # install ip netns
    pvt_iproute2_install

    # brctl
    pvt_brctl_install

    # ipmitool
    pvt_ipmitool_install
}

#----------------------------------------------------------

# set up env for ovs tests

configure_env()
{
    # make sure SELInux is enabled to check for BZ1262357.  may not be possible to enable in DPDK scenario.
    if [[ $(getenforce) != "Enforcing" ]]; then setenforce 1; sleep 2; getenforce; fi

    # disable a particular NIC driver for a test if so desired.  this is blank by default unless specified in job xml file
    if [[ $iface_driver != $disabled_nic_driver ]]; then
        disable_nic_driver $disabled_nic_driver
    else
        echo "The NIC driver that you are trying to disable is the driver under test.  This is not allowed."
    fi

    # display NIC driver details
    get_nic_driver_info

    # disable IPv6 Duplicate Adress Detection (DAD) in attempt to avoid being stuck in Tentative state
    echo 0 > /proc/sys/net/ipv6/conf/$iface/accept_dad

    # configure static IP addresses for the interface under test on the host
    #if [[ $rhel_version -ge 7 ]]; then
    #    create-iface-nmcli static-$iface $iface $ip4addr $ip6addr
    #else
    #    create-iface-ip-ifcfg $iface $ip4addr $ip6addr
    #fi
    #get-iface-info $iface

    # stop security features
    iptables_stop_flush

    # enable vxlan offload for mlx4_en driver
    if [[ $rhel_version -ge 7 && $iface_driver == "mlx4_en" ]]; then
        echo "$iface_driver will be set up to support VXLAN offload."
	echo "options mlx4_core log_num_mgm_entry_size=-1 debug_level=1" > /etc/modprobe.d/mlx4_core.conf
	rmmod mlx4_en mlx4_ib mlx4_core; sleep 5; modprobe mlx4_core
    cat /etc/modprobe.d/mlx4_core.conf
    fi
    
    # create OVS bridge to support subsequent VM creation
    create-ovsbr-vsctl $ovsbr
    create-ovsbr-port-vsctl -phy $ovsbr $iface
    create-ovsbr-port-vsctl -internal $ovsbr $intport
    get-iface-info $iface
    get-iface-info $intport

    # VM related setup
    for i in $vm_list; do create-vm $i $vm_version $ovsbr; done

    # update kernel on the VM if specified
    if [[ $up_knl_vm == yes ]]; then
        for i in $vm_list; do update-kernel-vm $i; done
        update-kernel-vm $vm_name
    fi
    
    # set static IP address on VM
    if [[ $rhel_version -ge 7 ]]; then
        set-vm-ip-nmcli $vm_name $ip4addr_vm $ip6addr_vm
    else
        set-vm-ip-ifcfg $vm_name $ip4addr_vm $ip6addr_vm
    fi
}


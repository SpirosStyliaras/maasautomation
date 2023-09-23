*** Settings ***

Documentation    MaaS tasks suite for composing KVM instances as MaaS pods.
...
...    | Author  | Spiros Styliaras          |
...    | Contact | spirosstyliaras@gmail.com |
...

Variables    ${EXECDIR}/libraries/common_variables.py
Variables    ${RESOURCES}/maaslabsconfiguration.yml
Resource     ${RESOURCES}/maas_management.robot
Library      maascontroller.MaasController    ${${MAAS_SERVER}}[maas_url]    ${${MAAS_SERVER}}[maas_username]    ${${MAAS_SERVER}}[maas_password]     WITH NAME    MaasController
LIbrary      Collections
Library      OperatingSystem
LIbrary      String


*** Variables ***


*** Tasks ***

Add_KVM_Host
    [Documentation]    Add existing KVM host as MAAS pod.
    [Tags]    maas    Production
    ${maas_kvm_pod}=    MaasController.Add KVM Host    kvm_host_type=${${MAAS_SERVER}}[kvm_hosts][${KVM_HOST}][type]
    ...  kvm_hostname=${KVM_HOST}
    ...  kvm_power_address=${${MAAS_SERVER}}[kvm_hosts][${KVM_HOST}][address]
    ...  kvm_power_pass=${${MAAS_SERVER}}[kvm_hosts][${KVM_HOST}][password]
    ...  zone=${${MAAS_SERVER}}[kvm_hosts][${KVM_HOST}][zone]
    ...  kvm_cpu_over_commit_ratio=${${MAAS_SERVER}}[kvm_hosts][${KVM_HOST}][cpu_over_commit_ratio]
    ...  kvm_memory_over_commit_ratio=${${MAAS_SERVER}}[kvm_hosts][${KVM_HOST}][memory_over_commit_ratio]
    ${maas_kvm_pod}=    MaasController.Get KVM Host By Name    ${KVM_HOST}
    ${storage_pools}=    Get KVM Host Storage Pools Paths    ${maas_kvm_pod}
    Log    ${\n}::: KVM Host added as MaaS pod:${\n}===============================   console=${True}
    ${output}=    Catenate    SEPARATOR=
    ...    -FQDN: ${maas_kvm_pod.name} ${\n}-Host Type: ${maas_kvm_pod.type} ${\n}-System ID: ${maas_kvm_pod.host.system_id}${SPACE}
    ...    ${\n}-Power Address: ${maas_kvm_pod.parameters()['power_address']}${SPACE}
    ...    ${\n}-CPU Over Commit Ratio: ${maas_kvm_pod.cpu_over_commit_ratio} ${\n}-Memory Over Commit Ratio: ${maas_kvm_pod.memory_over_commit_ratio}${SPACE}
    ...    ${\n}-Zone: ${maas_kvm_pod.zone.name}  ${\n}-ID: ${maas_kvm_pod.id} ${\n}-Architectures: ${maas_kvm_pod.architectures}${SPACE}
    ...    ${\n}-Storage Pools: ${storage_pools}
    Log    ${output}    console=${True}


Create_KVM_Instance
    [Documentation]    Create a KVM instance (pod machine) using a KVM host.
    ...    Note: The names of the provisioned KVM VMs should obey to the following syntax rule: <alphanumeric>-<number>.
    ...    This is important in order to be able to create network interfaces in host server that respect the interface naming rules.
    [Tags]    maas    Production
    Comment    Create KVM Instance
    Log    ${\n}::: KVM hypervisor leveraged for creating KVM VMs: ${KVM_HOST}      console=${True}
    ${maas_kvm_pod}=    MaasController.Get KVM Host By Name    ${KVM_HOST}
    Log    ${\n}::: KVM hypervisor ${KVM_HOST} power address: ${maas_kvm_pod.parameters()['power_address']}    console=${True}

    # We will apply netplan to the created VM through MAAS after commissioning the added machine.
    # The default interface attached to the created VM is defined under the default_interface key in machine's maaslabsconfiguration.yml
    # The default_interface key contains the MAAS managed libvirt network (fabric + vid)
    # PXE boot on the default interface will be used for provisioning the KVM pod and the IP will be allocated from the default_interface subnet MAAS dynamic range.
    # MAAS automatically add the default interface to the commissioned machine.
    ${vm}=    MaasController.Create KVM Pod Machine    ${KVM_HOST}    ${MAAS_MACHINE}    machine_config=${${MAAS_SERVER}}[machines][${MAAS_MACHINE}]
    ${machine}=    Get Machine By System ID    ${vm['system_id']}

    ${rc}    ${output}    OperatingSystem.Run and Return RC and Output
    ...    sshpass -p ${${MAAS_SERVER}}[kvm_hosts][${KVM_HOST}][password] virsh --connect ${${MAAS_SERVER}}[kvm_hosts][${KVM_HOST}][address] domiflist ${MAAS_MACHINE}
    Should Be Equal As Integers    ${rc}    0    msg=Fail to list ${MAAS_MACHINE} libvirt interfaces    values=${True}
    Log    ${\n}::: KVM instance ${MAAS_MACHINE} libvirt default network interface:${\n}${output}     console=${True}

    Log    ${\n}::: Wait Machine ${MAAS_MACHINE} commissing    console=${True}
    ${status}    Wait Until Keyword Succeeds    ${${MAAS_SERVER}}[commission_timeout]min   30sec    maas_management.Check Machine Commission Status    ${machine.hostname}    READY
    Run Keyword If    '${status}' == 'FAILED_COMMISSIONING'    FAIL    Fail to commission machine ${machine.hostname}, current status:${status}
    ${machine}=    Get Machine By System ID    ${vm['system_id']}
    ${machine_hardware_uuid}=    OperatingSystem.Run
    ...    sshpass -p ${${MAAS_SERVER}}[kvm_hosts][${KVM_HOST}][password] virsh --connect ${${MAAS_SERVER}}[kvm_hosts][${KVM_HOST}][address] dominfo ${MAAS_MACHINE} | egrep UUID | awk '{print $2}'
    Log    ${\n}::: Created KVM instance ${machine.fqdn} with MAAS system ID ${machine.system_id} and libvirt ID ${machine_hardware_uuid}    console=${True}

    Log    ${\n}::: Attach additional libvirt interfaces to KVM instance    console=${True}
    ${additional_interfaces}    Set Variable    ${${MAAS_SERVER}}[machines][${MAAS_MACHINE}][additional_interfaces]
    ${target_interface_name}    String.Fetch From Right    ${MAAS_MACHINE}    -
    ${target_interface_name}    Set Variable    vm-${target_interface_name}
    FOR    ${additional_interface}    IN    @{additional_interfaces}
    ${virsh_attach_command}=    Catenate    SEPARATOR=${SPACE}
        ...  sshpass -p ${${MAAS_SERVER}}[kvm_hosts][${KVM_HOST}][password] virsh --connect ${${MAAS_SERVER}}[kvm_hosts][${KVM_HOST}][address] attach-interface
        ...  --domain ${MAAS_MACHINE}
        ...  --type ${additional_interface.host_connection_type}
        ...  --source ${additional_interface.libvirt_network}
        ...  --target ${additional_interface.name}@${target_interface_name}
        ...  --model ${additional_interface.model}
        ...  --current
        ${rc}    ${output}    OperatingSystem.Run and Return RC and Output    ${virsh_attach_command}
        Should Be Equal As Integers    ${rc}    0    msg=Fail to attach interface ${additional_interface.name}    values=${True}
        Log  ${\n}::: Additional interface ${additional_interface.name} attached to KVM instance ${MAAS_MACHINE} with success    console=${True} 
    END

    ${rc}    ${output}    OperatingSystem.Run and Return RC and Output
    ...    sshpass -p ${${MAAS_SERVER}}[kvm_hosts][${KVM_HOST}][password] virsh --connect ${${MAAS_SERVER}}[kvm_hosts][${KVM_HOST}][address] domiflist ${MAAS_MACHINE}
    Should Be Equal As Integers    ${rc}    0    msg=Fail to list ${MAAS_MACHINE} libvirt interfaces    values=${True}
    Log    ${\n}::: KVM instance ${MAAS_MACHINE} libvirt network interfaces:${\n}${output}     console=${True}

    # Create dictionary with interface name as key and MAC address as value. Need when adding additional interfaces to MAAS.
    &{interfaces}=    Create Dictionary    &{EMPTY}
    FOR    ${additional_interface}    IN    @{additional_interfaces}
        ${mac_address}=    OperatingSystem.Run
        ...  sshpass -p ${${MAAS_SERVER}}[kvm_hosts][${KVM_HOST}][password] virsh --connect ${${MAAS_SERVER}}[kvm_hosts][${KVM_HOST}][address] domiflist ${MAAS_MACHINE} | egrep ${additional_interface.name} | awk '{print $5}'
        Set To Dictionary    ${interfaces}    ${additional_interface.name}=${mac_address}
    END

    # Comment    Add machine's additional interfaces in MaaS (manage interfaces through MaaS)
    FOR    ${additional_interface}    IN    @{additional_interfaces}
        ${interface}=    MaasController.Add Interface To Machine    machine_system_id=${machine.system_id}
        ...  interface_name=${additional_interface.name}
        ...  interface_type=${additional_interface.interface_type}
        ...  fabric_name=${additional_interface.fabric}
        ...  vlan=${additional_interface.vlan}
        ...  mac_address=${interfaces}[${additional_interface.name}]
        Log  ${\n}::: Additional interface ${interface.name} with MAC address ${interface.mac_address} added in MaaS with success    console=${True}
    END

    Comment    Configure link aggregations in MaaS if they exist
    ${link_aggregations}    Set Variable    ${${MAAS_SERVER}}[machines][${MAAS_MACHINE}][link_aggregations]
    IF    ${link_aggregations}
        FOR    ${link_aggregation}    IN    @{link_aggregations}
            ${interface}=    MaasController.Add Interface To Machine    machine_system_id=${machine.system_id}
            ...  interface_name=${link_aggregation.name}
            ...  interface_type=${link_aggregation.interface_type}
            ...  fabric_name=${link_aggregation.fabric}
            ...  vlan=${link_aggregation.vlan}
            ...  bond_parents_interfaces=${link_aggregation.parents}
            ...  bond_mode=${link_aggregation.bond_mode}
            ...  bond_miimon=${link_aggregation.bond_miimon}
            ...  bond_updelay=${link_aggregation.bond_updelay}
            ...  bond_downdelay=${link_aggregation.bond_downdelay}
            Log  ${\n}::: Bond ${link_aggregation.name} type: ${link_aggregation.bond_mode} for interfaces ${link_aggregation.parents} added in MaaS with success    console=${True}
        END
    ELSE
        Log  ${\n}::: No link aggregations configured for machine ${MAAS_MACHINE}    console=${True}
    END

    Comment    Configure bridges in MaaS if they exist
    ${bridges}    Set Variable    ${${MAAS_SERVER}}[machines][${MAAS_MACHINE}][bridges]
    IF    ${bridges}
        FOR    ${bridge}    IN    @{bridges}
            ${interface}=    MaasController.Add Interface To Machine    machine_system_id=${machine.system_id}
            ...  interface_name=${bridge.name}
            ...  interface_type=${bridge.interface_type}
            ...  fabric_name=${bridge.fabric}
            ...  vlan_name=${bridge.vlan}
            ...  bridge_parent_interface=${bridge.parent}
            ...  bridge_type=${bridge.bridge_type}
            ...  bridge_stp_enabled=${bridge.stp_enabled}
            Log  ${\n}::: Bridge ${bridge.name} type: ${bridge.bridge_type} for interface ${bridge.parent} added in MaaS with success    console=${True}
        END
    ELSE
        Log  ${\n}::: No bridges configured for machine ${MAAS_MACHINE}    console=${True}
    END

    Comment    Create links to machine interfaces (apply static IP netplan)
    ${links}    Set Variable    ${${MAAS_SERVER}}[machines][${MAAS_MACHINE}][links]
    FOR    ${link}    IN    @{links}
        ${interface_link}=    Link Interface    machine_system_id=${machine.system_id}
        ...  interface_name=${link.interface_name}
        ...  subnet_cidr=${link.subnet_cidr}
        ...  ip_address=${link.ip}
        Log    ${\n}::: Interface ${link.interface_name} linked with success    console=${True}
        ${link_configuration}=    Catenate    SEPARATOR=
        ...    -Interface: ${link.interface_name} ${\n}-IP: ${interface_link.ip_address} ${\n}-Subnet CIDR: ${interface_link.subnet.cidr}${SPACE}
        ...    ${\n}-VLAN name: ${interface_link.subnet.vlan.name} VLAN ID: ${interface_link.subnet.vlan.vid}
        Log    ${link_configuration}    console=${True}
    END

    ${rc}    ${output}    OperatingSystem.Run and Return RC and Output    sshpass -p ${${MAAS_SERVER}}[kvm_hosts][${KVM_HOST}][password] virsh --connect ${${MAAS_SERVER}}[kvm_hosts][${KVM_HOST}][address] list --all
    Should Be Equal As Integers    ${rc}    0    msg=Fail to list KVM instances    values=${True}
    Log    ${\n}::: Total provisioned KVM instances:${\n}${output}     console=${True}


*** Keywords ***
Get KVM Host Storage Pools Paths
    [Arguments]    ${kvm_pod}
    [Documentation]    Keyword to return the paths of the KVM host's configured storage pools.
    @{storage_pools_paths}    Create List    @{EMPTY}
    FOR    ${storage_pool}    IN    @{kvm_pod._orig_data['storage_pools']}
        Append To List    ${storage_pools_paths}    ${storage_pool['path']}
    END
    [Return]    ${storage_pools_paths}

*** Settings ***

Documentation    MaaS tasks suite for commissioning and deploying machines.
...
...    | Author  | Spiros Styliaras          |
...    | Contact | spirosstyliaras@gmail.com |
...

Variables    ${EXECDIR}/libraries/common_variables.py
Variables    ${RESOURCES}/maaslabsconfiguration.yml
Resource     ${RESOURCES}/maas_management.robot
Library      maascontroller.MaasController    ${${MAAS_SERVER}}[maas_url]    ${${MAAS_SERVER}}[maas_username]    ${${MAAS_SERVER}}[maas_password]     WITH NAME    MaasController
Library      Collections
Library      DateTime
Library      String


*** Variables ***
${EVENT_ENTRIES}    30


*** Tasks ***

List_MAAS_Machines
    [Documentation]  List all MAAS machines of Rack controller.
    [Tags]    maas    Production
    Comment    List all MAAS machines
    Log    ${\n}::: MAAS Machines:${\n}==================    console=${True}
    ${machines}=    MaasController.Get Machines
    FOR    ${machine}    IN    @{machines}
        Log    ${\n}Machine ${machine.hostname}:    console=${True}
        ${storage}=    MaasController.Get Machine Total Storage Size  ${machine.hostname}
        ${hw_details}=    MaasController.Get Machine HW Details    ${machine.system_id}
        ${machine_tags}=    Get Machine Tags    ${machine}
        ${output}=    Catenate    SEPARATOR=
        ...    -FQDN:${machine.fqdn} ${\n}-IPs:${machine.ip_addresses} ${\n}-Status:${machine.status.name}${SPACE}
        ...    ${\n}-OS:${machine.osystem} Release:${machine.distro_series} HWE_Kernel:${machine.hwe_kernel}${SPACE}
        ...    ${\n}-Power-state:${machine.power_state.name} ${\n}-Power-type:${machine.power_type} ${\n}-Architecture:${machine.architecture}${SPACE}
        ...    ${\n}-CPUs:${machine.cpus} ${\n}-RAM:${machine.memory} ${\n}-Storage Size:${storage}GB${SPACE}
        ...    ${\n}-Resource-Pool:${machine.pool.name} ${\n}-Tags:${machine_tags}${SPACE}
        ...    ${\n}-Zones:${machine.zone.name} ${\n}-MAAS System Id:${machine.system_id}
        Log    ${output}    console=${True}
    END


Power_On_Machine
    [Documentation]  Task to power-on machine.
    [Tags]    maas    Production
    Comment    Power On Machine
    ${machine}=    MaasController.Get Machine By Hostname    hostname=${MAAS_MACHINE}
    Run Keyword If    '${machine.power_state.name}' == 'ON'
    ...    Pass Execution    ${\n} ::: Machine ${MAAS_MACHINE} already powered-on, skipping task.
    ...    ELSE   MaasController.Power On Machine    ${machine.system_id}
    Wait Until Keyword Succeeds    5min    10sec  maas_management.Check Machine Power Status    ${MAAS_MACHINE}    ON
    Log    ${\n} ::: Machine ${MAAS_MACHINE} - system_id: ${machine.system_id} powered-on with success.    console=${True}


Power_Off_Machine
    [Documentation]  Task to power-off machine.
    [Tags]    maas    Production
    Comment    Power Off Machine
    ${machine}=    MaasController.Get Machine By Hostname    hostname=${MAAS_MACHINE}
    Run Keyword If    '${machine.power_state.name}' == 'OFF'
    ...    Pass Execution    ${\n} ::: Machine ${MAAS_MACHINE} already powered-off, skipping task.
    ...    ELSE   MaasController.Power Off Machine    ${machine.system_id}
    Wait Until Keyword Succeeds    5min    10sec  maas_management.Check Machine Power Status    ${MAAS_MACHINE}    OFF
    Log    ${\n} ::: Machine ${MAAS_MACHINE} - system_id: ${machine.system_id} powered-off with success.    console=${True}


Power_On_All_Deployed_Machines
    [Documentation]  Task to power-on all deployed machines.
    [Tags]  maas    Production    PowerOnRack
    Comment    List all MAAS machines with tag
    ${powered_off_deployed_machines}=    MaasController.Get Powered Off Deployed Machines
    Log List  ${powered_off_deployed_machines}
    ${status}=    Run Keyword And Return Status    Should Not Be Empty    ${powered_off_deployed_machines}
    Run Keyword If    ${status} == ${False}    Pass Execution    ::: No powered-off deployed machines, skipping task.
    Log    ${\n}::: Powered-off deployed MAAS Machines: ${\n}${powered_off_deployed_machines}    console=${True}
    
    Comment    Power-on deployed powered-off MAAS machines
    FOR    ${machine}    IN    @{powered_off_deployed_machines}
        MaasController.Power On Machine    ${machine.system_id}
    END
    Log    ${\n}::: Deployed MAAS Machines powered-on with success.    console=${True}


Power_Off_All_Deployed_Machines
    [Documentation]  Task to power-off all deployed machines.
    [Tags]  maas    Production    PowerOffRack
    Comment    List all powered-on deployed MAAS machines
    ${powered_on_deployed_machines}=    MaasController.Get Powered On Deployed Machines
    Log List  ${powered_on_deployed_machines}
    ${status}=    Run Keyword And Return Status    Should Not Be Empty    ${powered_on_deployed_machines}
    Run Keyword If    ${status} == ${False}    Pass Execution    ::: No powered-on deployed machines, skipping task.
    Log    ${\n}::: Powered-on deployed MAAS Machines: ${\n}${powered_on_deployed_machines}    console=${True}
    
    Comment    Power-off deployed powered-on MAAS machines
    FOR    ${machine}    IN    @{powered_on_deployed_machines}
        MaasController.Power Off Machine    ${machine.system_id}
    END
    Log    ${\n}::: Deployed MAAS Machines powered-off with success.    console=${True}


Power_On_Machines_by_Tag
    [Documentation]  Task to power-on all machines by given tag value.
    [Tags]  maas    Production
    Comment    List all deployed MAAS machines with tag ${MAAS_TAG}
    ${machines}=    MaasController.Get Machines By Tag    ${MAAS_TAG}
    ${status}=    Run Keyword And Return Status    Should Not Be Empty    ${machines}
    Run Keyword If    ${status} == ${False}    Pass Execution    ::: No machines with selected tag ${MAAS_TAG}, skipping task.
    Log List    ${machines}
    Log    ${\n}::: Machines with tag ${MAAS_TAG}: ${machines}:    console=${True}

    ${powered_on_tagged_deployed_machines}=    MaasController.Get Powered On Deployed Machines by Tag    ${MAAS_TAG}
    Log    ${\n}::: Powered-on deployed MAAS Machines with tag ${MAAS_TAG}: ${\n}${powered_on_tagged_deployed_machines}    console=${True}

    ${powered_off_tagged_deployed_machines}=    MaasController.Get Powered Off Deployed Machines by Tag    ${MAAS_TAG}
    Log    ${\n}::: Powered-off deployed MAAS Machines with tag ${MAAS_TAG}: ${\n}${powered_off_tagged_deployed_machines}    console=${True}

    Comment    Power-on deployed MAAS machines
    FOR    ${machine}    IN    @{powered_off_tagged_deployed_machines}
        MaasController.Power On Machine    ${machine.system_id}
        Log    ${\n}::: MAAS Machine ${machine.hostname} powered-on with success    console=${True}
    END


Power_Off_Machines_by_Tag
    [Documentation]  Task to power-off all machines by given tag value.
    [Tags]  maas    Production
    Comment    List all deployed MAAS machines with tag ${MAAS_TAG}
    ${machines}=    MaasController.Get Machines By Tag    ${MAAS_TAG}
    ${status}=    Run Keyword And Return Status    Should Not Be Empty    ${machines}
    Run Keyword If    ${status} == ${False}    Pass Execution    ::: No machines with selected tag ${MAAS_TAG}, skipping task.
    Log List    ${machines}
    Log    ${\n}::: Machines with tag ${MAAS_TAG}: ${machines}:    console=${True}

    ${powered_on_tagged_deployed_machines}=    MaasController.Get Powered On Deployed Machines by Tag    ${MAAS_TAG}
    Log    ${\n}::: Powered-on deployed MAAS Machines with tag ${MAAS_TAG}: ${\n}${powered_on_tagged_deployed_machines}    console=${True}

    ${powered_off_tagged_deployed_machines}=    MaasController.Get Powered Off Deployed Machines by Tag    ${MAAS_TAG}
    Log    ${\n}::: Powered-off deployed MAAS Machines with tag ${MAAS_TAG}: ${\n}${powered_off_tagged_deployed_machines}    console=${True}

    Comment    Power-off deployed MAAS machines
    FOR    ${machine}    IN    @{powered_on_tagged_deployed_machines}
        MaasController.Power Off Machine    ${machine.system_id}
        Log    ${\n}::: MAAS Machine ${machine.hostname} powered-off with success    console=${True}
    END


Commission_MAAS_Machine
    [Documentation]  Task for commissioning enlisted MaaS machine.
    [Tags]    maas    Production
    Comment    Set Ubuntu Release for Commissioning
    ${ubuntu_release}=    Set Variable  ${${MAAS_SERVER}}[default_commission_ubuntu_os][release]
    ${min_hwe_kernel}=    Set Variable  ${${MAAS_SERVER}}[default_commission_ubuntu_os][minimum_hwe_kernel]
    MaasController.Set Default Ubuntu Commissioning Release    ${ubuntu_release}    ${min_hwe_kernel}
    Log    ${\n}::: Ubuntu commissioning release selected: ${ubuntu_release}/${min_hwe_kernel}      console=${True}

    ${machine}=    Get Machine By Hostname    ${MAAS_MACHINE}
    Comment    Set Machine hostname
    MaasController.Set Machine Hostname    ${machine.system_id}    ${MAAS_MACHINE_HOSTNAME}
    ${machine}=    Get Machine By Hostname    ${MAAS_MACHINE_HOSTNAME}
    Log    ${\n}::: MAAS Machine to be commissioned: ${machine.hostname} - system_id: ${machine.system_id}    console=${True}
    Log    ${\n}::: MAAS Machine ${MAAS_MACHINE} hostname set to ${MAAS_MACHINE_HOSTNAME}    console=${True}

    Comment   Commission MAAS Machine
    ${commissionStartTimestamp}=    DateTime.Get Current Date
    MaasController.Commission Machine    ${machine.system_id}   enable_ssh=${True}    skip_networking=${True}    wait_commission_complete=${False}
    ${status}    Wait Until Keyword Succeeds    ${${MAAS_SERVER}}[commission_timeout]min    30sec    maas_management.Check Machine Commission Status    ${machine.hostname}    READY
    Run Keyword If    '${status}' == 'FAILED_COMMISSIONING'    FAIL    Fail to commission machine ${machine.hostname}, current status:${status}
    ${commissionCompleteTimestamp}=    DateTime.Get Current Date
    ${timeTotalSeconds} =    Subtract Date From Date    ${commissionCompleteTimestamp}    ${commissionStartTimestamp}
    Log    ${\n}::: Machine ${machine.hostname} commission completed with success after ${timeTotalSeconds} seconds.   console=${True}

    [Teardown]    Log Machine Events    ${MAAS_MACHINE}    ${EVENT_ENTRIES}


Deploy_MAAS_Machine
    [Documentation]    Task for deploying commissioned MaaS machine.
    [Tags]    maas    Production
    Comment    Set Operating System for Deployment
    ${operating_system}=    Set Variable    ${${MAAS_SERVER}}[machines][${MAAS_MACHINE}][deployment_os][operating_system]
    ${release}=    Set Variable    ${${MAAS_SERVER}}[machines][${MAAS_MACHINE}][deployment_os][release]
    MaasController.Set Default Deployment Operating System    ${operating_system}    ${release}
    Log    ${\n}::: Deployment Operating System configured: ${operating_system}/${release}      console=${True}

    Comment   Allocate MAAS Machine
    ${machine}=    Get Machine By Hostname    ${MAAS_MACHINE}
    Log    ${\n}::: MAAS Machine to be deployed: ${machine.hostname} - system_id: ${machine.system_id}    console=${True}
    MaasController.Acquire Machine    ${machine.hostname}

    Comment   Deploy MAAS Machine
    ${deployStartTimestamp}=    DateTime.Get Current Date
    MaasController.Deploy Machine    ${machine.system_id}    wait_deploy_complete=${False}
    ${status}    Wait Until Keyword Succeeds    ${${MAAS_SERVER}}[deploy_timeout]min     30sec    Check Machine Deploy Status    ${machine.hostname}    DEPLOYED
    Run Keyword If    '${status}' == 'FAILED_DEPLOYMENT'    FAIL    Fail to deploy machine ${machine.hostname}, current status:${status}
    ${deployCompleteTimestamp}=    DateTime.Get Current Date
    ${timeTotalSeconds} =    Subtract Date From Date    ${deployCompleteTimestamp}    ${deployStartTimestamp}
    Log    ${\n}::: Machine ${machine.hostname} deployment completed with success after ${timeTotalSeconds} seconds   console=${True}

    Comment    Add Tags to deployed Machine
    maas_management.Add Machine Tags    ${MAAS_MACHINE}    ${${MAAS_SERVER}}[machines][${MAAS_MACHINE}][tags]
    Log    ${\n}::: Tags added to Machine ${machine.hostname}: ${${MAAS_SERVER}}[machines][${MAAS_MACHINE}][tags]   console=${True}

    Comment    Add Machine to resources pool
    MaasController.Add Machine To Resource Pool    ${machine.system_id}    ${${MAAS_SERVER}}[machines][${MAAS_MACHINE}][pool]
    Log    ${\n}::: Machine ${machine.hostname} added to resource pool ${${MAAS_SERVER}}[machines][${MAAS_MACHINE}][pool]   console=${True}

    [Teardown]    Log Machine Events    ${MAAS_MACHINE}    ${EVENT_ENTRIES}


Commission_And_Deploy_MAAS_Machine
    [Documentation]    Task for commissioning and deploying MaaS machine.
    [Tags]    maas    Production
    Comment    Set Ubuntu Release for Commissioning
    ${ubuntu_release}=    Set Variable  ${${MAAS_SERVER}}[default_commission_ubuntu_os][release]
    ${min_hwe_kernel}=    Set Variable  ${${MAAS_SERVER}}[default_commission_ubuntu_os][minimum_hwe_kernel]
    MaasController.Set Default Ubuntu Commissioning Release    ${ubuntu_release}    ${min_hwe_kernel}
    Log    ${\n}::: Ubuntu commissioning release selected: ${ubuntu_release}/${min_hwe_kernel}      console=${True}

    ${machine}=    Get Machine By Hostname    ${MAAS_MACHINE}
    Comment    Set Machine hostname
    MaasController.Set Machine Hostname    ${machine.system_id}    ${MAAS_MACHINE_HOSTNAME}
    ${machine}=    Get Machine By Hostname    ${MAAS_MACHINE_HOSTNAME}
    Log    ${\n}::: MAAS Machine to be commissioned: ${machine.hostname} - system_id: ${machine.system_id}    console=${True}
    Log    ${\n}::: MAAS Machine ${MAAS_MACHINE} hostname set to ${MAAS_MACHINE_HOSTNAME}    console=${True}

    Comment   Commission MAAS Machine
    ${commissionStartTimestamp}=    DateTime.Get Current Date
    MaasController.Commission Machine    ${machine.system_id}   enable_ssh=${True}    skip_networking=${True}    wait_commission_complete=${False}
    ${status}    Wait Until Keyword Succeeds    ${${MAAS_SERVER}}[commission_timeout]min   30sec    maas_management.Check Machine Commission Status    ${machine.hostname}    READY
    Run Keyword If    '${status}' == 'FAILED_COMMISSIONING'    FAIL    Fail to commission machine ${machine.hostname}, current status:${status}
    ${commissionCompleteTimestamp}=    DateTime.Get Current Date
    ${timeTotalSeconds} =    Subtract Date From Date    ${commissionCompleteTimestamp}    ${commissionStartTimestamp}
    Log    ${\n}::: Machine ${machine.hostname} commission completed with success after ${timeTotalSeconds} seconds.   console=${True}

    Log    ${\n}::: Machine ${machine.hostname} commissionning logs:    console=${True}
    Log Machine Events    ${MAAS_MACHINE}    ${EVENT_ENTRIES} 

    Sleep    10 sec
    MaasController.Acquire Machine    ${machine.hostname}
    Sleep    10 sec

    Comment   Deploy MAAS Machine
    ${deployStartTimestamp}=    DateTime.Get Current Date
    MaasController.Deploy Machine    ${machine.system_id}    wait_deploy_complete=${False}   
    ${status}    Wait Until Keyword Succeeds    ${${MAAS_SERVER}}[deploy_timeout]min    30sec    Check Machine Deploy Status    ${machine.hostname}    DEPLOYED
    Run Keyword If    '${status}' == 'FAILED_DEPLOYMENT'    FAIL    Fail to deploy machine ${machine.hostname}, current status:${status}
    ${deployCompleteTimestamp}=    DateTime.Get Current Date
    ${timeTotalSeconds} =    Subtract Date From Date    ${deployCompleteTimestamp}    ${deployStartTimestamp}
    Log    ${\n}::: Machine ${machine.hostname} deployment completed with success after ${timeTotalSeconds} seconds.   console=${True}

    Comment    Add Tags to deployed Machine
    maas_management.Add Machine Tags    ${MAAS_MACHINE}    ${${MAAS_SERVER}}[machines][${MAAS_MACHINE}][tags]
    Log    ${\n}::: Tags added to Machine ${machine.hostname}: ${${MAAS_SERVER}}[machines][${MAAS_MACHINE}][tags]   console=${True}

    Comment    Add Machine to resources pool
    MaasController.Add Machine To Resource Pool    ${machine.system_id}    ${${MAAS_SERVER}}[machines][${MAAS_MACHINE}][pool]
    Log    ${\n}::: Machine ${machine.hostname} added to resource pool ${${MAAS_SERVER}}[machines][${MAAS_MACHINE}][pool]   console=${True}

    [Teardown]    Log Machine Events    ${MAAS_MACHINE}    ${EVENT_ENTRIES}


Release_MAAS_Machine
    [Documentation]  Task for releasing enlisted MaaS machine. Release means returning a machine back into the pool of available nodes, 
    ...    changing a node’s status from Deployed (or Allocated) to Ready.
    [Tags]    maas    Production
    ${machine}=    Get Machine By Hostname    hostname=${MAAS_MACHINE}
    Log    ${\n}::: MaaS Machine to be released: ${machine.hostname} - system_id: ${machine.system_id}    console=${True}
    MaasController.Release Machine    ${machine.system_id}    wait_release_complete=${False}
    ${status}    Wait Until Keyword Succeeds    ${${MAAS_SERVER}}[release_timeout]min   30sec    maas_management.Check Machine Commission Status    ${machine.hostname}    READY
    Run Keyword If    ${status}    FAIL    Fail to release machine ${machine.hostname}, current status:${status}
    Log    ${\n} ::: MaaS Machine ${MAAS_MACHINE} - system_id: ${machine.system_id} released with success.    console=${True}


Release_Machines_by_Tag
    [Documentation]  Task to release all machines by given tag value.
    [Tags]  maas    Production
    Comment    List all MaaS machines with tag ${MAAS_TAG}
    ${machines}=    MaasController.Get Machines By Tag    ${MAAS_TAG}
    ${status}=    Run Keyword And Return Status    Should Not Be Empty    ${machines}
    Run Keyword If    ${status} == ${False}    Pass Execution    ::: No machines with selected tag ${MAAS_TAG}, skipping task.
    Log List    ${machines}
    Log    ${\n}::: Machines with tag ${MAAS_TAG}: ${machines}:    console=${True}

    Comment    Release MAAS machines
    FOR    ${machine}    IN    @{machines}
         MaasController.Release Machine  machine_system_id=${machine.system_id}    wait_release_complete=${True}
         Log    ${\n}::: MAAS Machine ${machine.hostname} released with success    console=${True}
     END


Delete_MAAS_Machine
    [Documentation]  Task for deleting enlisted MaaS machine.
    [Tags]    maas    Production
    ${machine}=    Get Machine By Hostname    hostname=${MAAS_MACHINE}
    Log    ${\n}::: MaaS Machine to be deleted: ${machine.hostname} - system_id: ${machine.system_id}    console=${True}
    MaasController.Delete Machine    ${machine.system_id}
    Run Keyword And Expect Error    Machine with hostname ${MAAS_MACHINE} not found.     Get Machine By Hostname    hostname=${MAAS_MACHINE}
    Log    ${\n} ::: MaaS Machine ${MAAS_MACHINE} deleted with success.    console=${True}



*** Keywords ***
Log Machine Events
    [Arguments]    ${machine_hostname}    ${event_entries_num}
    [Documentation]    Log machine events.
    ${machine}=    MaasController.Get Machine By Hostname    hostname=${machine_hostname}
    ${events}=    MaasController.Get Machine Events    ${machine.hostname}   ${event_entries_num}
    Log    ${\n}::: MAAS Machine events:${\n}    console=${True}
    FOR    ${event}    IN    @{events}
        Log    timestamp:${event['created']} id:${event['id']} type:${event['type']}    console=${True}
    END

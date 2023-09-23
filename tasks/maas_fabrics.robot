*** Settings ***

Documentation    MaaS tasks suite for Fabrics and VLANs.
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


*** Tasks ***

List_MAAS_Fabrics
    [Documentation]    List MAAS Fabrics' configuration.
    [Tags]    maas    Production
    Comment    List all MAAS configured Fabrics
    Log    ${\n}::: MAAS Fabrics:${\n}=================    console=${True}
    ${fabrics}=    MaasController.Get Fabrics
    FOR    ${fabric}    IN    @{fabrics}
        Log    ${\n}Fabric ${fabric.name}:    console=${True}
        ${vlans}=    MaasController.Get Fabric VLANs    ${fabric.name}
        ${vlan_names}=    MaasController.Get Fabric VLAN Names    ${fabric.name}
        ${output}=    Catenate    SEPARATOR=
        ...    -Fabric ID:${fabric.id} ${\n}-Loaded:${fabric.loaded}${SPACE}
        ...    ${\n}-VLANs:${vlans}
        ...    ${\n}-VLAN names:${vlan_names}
        Log    ${output}    console=${True}
    END


List_MAAS_VLANs
    [Documentation]    List VLANs' subnet configuration.
    [Tags]    maas    Production
    Comment    List all MAAS configured VLAN subnets
    Log    ${\n}::: MAAS VLAN subnets:${\n}======================    console=${True}
    ${vlans}=    MaasController.Get VLANs
    FOR    ${vlan}    IN    @{vlans}
        &{vlan_identifiers}=    Create Dictionary    name=${vlan.name}    id=${vlan.id}
        Log    ${\n}VLAN: ${vlan_identifiers}:    console=${True}
        ${subnets}=    MaasController.Get VLAN Subnets CIDRs    ${vlan.id}
        ${output}=    Catenate    SEPARATOR=
        ...    -Subnets:${subnets} ${\n}-MTU:${vlan.mtu}${SPACE}
        ...    ${\n}-Fabric ID:${vlan.fabric.id} ${\n}-Vid:${vlan.vid}
        Log    ${output}    console=${True}
    END


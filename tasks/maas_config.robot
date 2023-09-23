*** Settings ***

Documentation    MaaS server settings configuration tasks suite.
...
...    | Author  | Spiros Styliaras          |
...    | Contact | spirosstyliaras@gmail.com |
...

Variables    ${EXECDIR}/libraries/common_variables.py
Variables    ${RESOURCES}/maaslabsconfiguration.yml
Resource     ${RESOURCES}/maas_management.robot
Library      maascontroller.MaasController    ${${MAAS_SERVER}}[maas_url]    ${${MAAS_SERVER}}[maas_username]    ${${MAAS_SERVER}}[maas_password]     WITH NAME    MaasController
Library      Collections
Library      String


*** Variables ***



*** Tasks ***

Set_MaaS_Machines_Tags
    [Documentation]    Configure MaaS machines tags
    [Tags]    maas    Production
    Comment    Set required MAAS machines tags
    ${existing_tags}=    MaasController.Get Tag Names
    Log    ${\n}::: Currently configured MAAS tags:    console=${True}
    Log    ${existing_tags}    console=${True}
    ${required_tags_names}    Create List    @{EMPTY}
    ${required_tags}=    Set Variable    ${${MAAS_SERVER}}[tags]
    FOR    ${tag}    IN    @{required_tags}
        Append To List    ${required_tags_names}    ${tag.name} 
    END
    Log    ${\n}::: Required MAAS tags:    console=${True}
    Log    ${required_tags_names}   console=${True}
    Comment    Delete existing tags
    FOR    ${tag}    IN    @{existing_tags}
        MaasController.Delete Tag    ${tag}    
    END
    Comment    Create required tags
    FOR    ${tag}    IN    @{required_tags} 
        MaasController.Create Tag    ${tag.name}    ${tag.description}
    END
    ${existing_tags}=    MaasController.Get Tag Names
    Should Be Equal    ${required_tags_names}    ${existing_tags}    msg=Failed to configured required tags    values=${True}


Configure_Default_Ubuntu_Commissioning_Operating_System
    [Documentation]    Configure default commissioning Ubuntu operating system.
	[Tags]    maas    Production
    Comment    Set Ubuntu OS release for Commissioning
    ${ubuntu_release}=    Set Variable  ${${MAAS_SERVER}}[default_commission_ubuntu_os][release]
    ${min_hwe_kernel}=    Set Variable  ${${MAAS_SERVER}}[default_commission_ubuntu_os][minimum_hwe_kernel]
    MaasController.Set Default Ubuntu Commissioning Release    ${ubuntu_release}    ${min_hwe_kernel}  
    Log    ${\n}::: Ubuntu commissioning release selected: ${ubuntu_release}/${min_hwe_kernel}      console=${True}


Configure_Default_Deployment_Operating_System
    [Documentation]    Configure default deployment operating system and release.
	[Tags]    maas    Production
    Comment    Set Operating System for Deployment
    ${operating_system}=    Set Variable  ${${MAAS_SERVER}}[default_deployment_os][operating_system]
    ${release}=    Set Variable  ${${MAAS_SERVER}}[default_deployment_os][release]
    MaasController.Set Default Deployment Operating System    ${operating_system}    ${release}  
    Log    ${\n}::: Default Deployment Operating System configured: ${operating_system}/${release}      console=${True}


Set_MaaS_Availability_Zones
    [Documentation]    Configure MaaS AZs.
    [Tags]    maas    Production
    Comment    Set required MAAS Availability Zones
    ${existing_zones}=    MaasController.Get Availability Zones Names 
    Log    ${\n}::: Currently configured MAAS AZs:    console=${True}
    Log    ${existing_zones}    console=${True}
    ${required_zones}=    Set Variable    ${${MAAS_SERVER}}[availability_zones]
    FOR    ${zone}    IN    @{required_zones}
         ${status}    ${return_value}    Run Keyword And Ignore Error    MaasController.Create Availability Zone    ${zone.name}    ${zone.description}
         ${already_exists}    Run Keyword And Return Status    Should Contain    ${return_value}    Physical zone with this Name already
         Run Keyword If    '${status}' == 'FAIL'
         ...  Run Keyword If  ${already_exists} == ${False}    Fail    msg=Fail to create AZ ${zone.name}
         Log    ${\n}::: AZ ${zone.name} configured in MaaS    console=${True}     
    END


Set_MaaS_Resource_Pools
    [Documentation]    Configure MaaS resource pools.
    [Tags]    maas    Production
    Comment    Set required MAAS resource pools
    ${existing_pools}=    MaasController.Get Resource Pools Names 
    Log    ${\n}::: Currently configured MAAS Resource Pools:    console=${True}
    Log    ${existing_pools}    console=${True}
    ${resource_pools}=    Set Variable    ${${MAAS_SERVER}}[resource_pools]
    FOR    ${pool}    IN    @{resource_pools}
         ${status}    ${return_value}    Run Keyword And Ignore Error    MaasController.Create Resource Pool    ${pool.name}    ${pool.description}
         ${already_exists}    Run Keyword And Return Status    Should Contain    ${return_value}    Resource pool with this Name already
         Run Keyword If    '${status}' == 'FAIL'
         ...  Run Keyword If  ${already_exists} == ${False}    Fail    msg=Fail to create resource pool ${pool.name}
         Log    ${\n}::: Resource pool ${pool.name} configured in MaaS    console=${True}     
    END



*** Keywords ***
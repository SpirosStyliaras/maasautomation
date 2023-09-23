*** Settings ***
Documentation    Common keywords for MaaS management.
...
...
...    | Author  | Spiros Styliaras          |
...    | Contact | spirosstyliaras@gmail.com |
...

Library      maascontroller.MaasController    ${${MAAS_SERVER}}[maas_url]    ${${MAAS_SERVER}}[maas_username]    ${${MAAS_SERVER}}[maas_password]     WITH NAME    MaasController

*** Variables ***


*** Keywords ***

Check Machine Power Status
    [Arguments]    ${hostname}    ${expectedPowerStatus}
    [Documentation]     Check Machine's power status.
    ${machine}=    MaasController.Get Machine By Hostname    hostname=${hostname}
    Should Be Equal As Strings    ${machine.power_state.name}    ${expectedPowerStatus}    msg=FAIL: Machine ${machine.hostname} failed to power ${expectedPowerStatus}    values=${True}


Check Machine Commission Status
    [Arguments]    ${hostname}    ${expectedStatus}
    [Documentation]     Check Machine's commissioning status.
    ${machine}=    MaasController.Get Machine By Hostname    hostname=${hostname}
    Log    ${\n}::: Machine ${hostname} status: ${machine.status.name}    console=${True}
    Return From Keyword If    '${machine.status.name}' == 'FAILED_COMMISSIONING'    ${machine.status.name}
    Should Be Equal As Strings    ${machine.status.name}    ${expectedStatus}    msg=FAIL: Machine ${machine.hostname} not in expected status ${expectedStatus}    values=${True}


Check Machine Deploy Status
    [Arguments]    ${hostname}    ${expectedStatus}
    [Documentation]     Check Machine's deploy status.
    ${machine}=    MaasController.Get Machine By Hostname    hostname=${hostname}
    Log    ${\n}::: Machine ${hostname} status: ${machine.status.name}    console=${True}
    Return From Keyword If    '${machine.status.name}' == 'FAILED_DEPLOYMENT'    ${machine.status.name}
    Should Be Equal As Strings    ${machine.status.name}    ${expectedStatus}    msg=FAIL: Machine ${machine.hostname} not in expected status ${expectedStatus}    values=${True}


Check Machine Status
    [Arguments]    ${hostname}    ${expectedStatus}
    [Documentation]     Check Machine's status.
    ${machine}=    MaasController.Get Machine By Hostname    hostname=${hostname}
    Log    ${\n}::: Machine ${hostname} status: ${machine.status.name}    console=${True}
    Should Be Equal As Strings    ${machine.status.name}    ${expectedStatus}    msg=FAIL: Machine ${machine.hostname} not in expected status ${expectedStatus}    values=${True}


Get Machine Tags
    [Arguments]    ${machine}
    [Documentation]    Return list with tags attached to selected machine.
    @{tags}=    Create List    @{EMPTY}
    FOR    ${tag}    IN    @{machine.tags._items}
        Collections.Append To List    ${tags}    ${tag.name}
    END
    [Return]    ${tags}


Create Machine Tag
    [Arguments]    ${tag_name}
    [Documentation]    Return list with tags attached to selected machine.
    ${tags}=    MaasController.Get Tag Names
    ${status}    Run Keyword And Return Status    Should Contain    ${tags}    ${tag_name}
    Run Keyword Unless    ${status}    MaasController.Create Tag    ${tag_name}


Add Machine Tags
    [Arguments]    ${hostname}    ${tags_list}
    [Documentation]    Add tags to machine.
    ${machine}=    MaasController.Get Machine By Hostname    hostname=${hostname}
    FOR    ${tag}    IN    @{tags_list}
        MaasController.Add Tag To Machine    ${machine.system_id}    ${tag}
    END
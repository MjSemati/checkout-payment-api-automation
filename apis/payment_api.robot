*** Settings ***
Library    RequestsLibrary


*** Keywords ***
Get Payment Methods Response
    [Arguments]    ${base_url}    ${endpoint}

    Create Session    checkout_api    ${base_url}
    ${response}=    GET On Session    checkout_api    ${endpoint}    expected_status=any

    RETURN    ${response}
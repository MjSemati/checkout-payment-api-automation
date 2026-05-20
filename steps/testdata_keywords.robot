*** Settings ***
Library    Collections
Library    JSONLibrary

*** Variables ***
${TESTDATA_SCENARIOS_DIR}    ${CURDIR}${/}..${/}testdata${/}scenarios
# Set by Store Response Context in payment_keywords.robot after the API call
${response}    ${NONE}

*** Keywords ***
Load Testdata Fixture
    [Arguments]    ${scenario}
    ${fixture_path}=    Set Variable    ${TESTDATA_SCENARIOS_DIR}${/}${scenario}.json
    ${fixture}=    Load Json From File    ${fixture_path}
    RETURN    ${fixture}

Get Expected HTTP Status From Fixture
    [Arguments]    ${fixture}
    ${has_http_status}=    Run Keyword And Return Status
    ...    Dictionary Should Contain Key    ${fixture}    http_status
    IF    ${has_http_status}
        ${http_status}=    Get From Dictionary    ${fixture}    http_status
        Remove From Dictionary    ${fixture}    http_status
        RETURN    ${http_status}    ${fixture}
    END
    RETURN    ${200}    ${fixture}

Get Testdata Response Body
    [Arguments]    ${scenario}
    ${fixture}=    Load Testdata Fixture    ${scenario}
    ${http_status}    ${body}=    Get Expected HTTP Status From Fixture    ${fixture}
    RETURN    ${http_status}    ${body}

Response Body Should Match Testdata Fixture
    [Arguments]    ${scenario}
    ${expected_http}    ${expected_body}=    Get Testdata Response Body    ${scenario}
    ${actual_body}=    Set Variable    ${response.json()}
    Should Be Equal As Integers    ${response.status_code}    ${expected_http}
    ...    msg=HTTP status should match testdata/${scenario}.json
    Dictionaries Should Be Equal    ${actual_body}    ${expected_body}
    ...    msg=Response body should match testdata/${scenario}.json

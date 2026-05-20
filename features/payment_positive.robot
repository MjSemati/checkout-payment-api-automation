*** Settings ***
Documentation    Positive payment API scenarios (S1-S2).
...
...    Prerequisites: start fake server before running tests:
...    \ \ python3 fake_server/app.py
Resource    ../steps/payment_keywords.robot
Resource    ../steps/testdata_keywords.robot

Default Tags    payment-api    checkout    positive    regression    api    fake-server

*** Variables ***
${BASE_URL}       http://127.0.0.1:8080
${CELL_NUMBER}    09120000000


*** Test Cases ***
S1 Happy Path - All Payment Methods And Rules Valid
    [Documentation]    S1 (positive): online, wallet, and BNPL are present,
    ...    all methods are clickable, and rules R1-R7 pass.
    [Tags]    S1    required    smoke    contract    online    wallet    bnpl    R1    R2    R3    R4    R5    R6    R7

    Given Payment API Is Available At    ${BASE_URL}
    When User Requests Payment Methods With Scenario    happy_path    ${CELL_NUMBER}
    Then Response Body Should Match Testdata Fixture    happy_path
    And Response Status Should Be Successful
    And Response Should Contain Payment Methods Array
    And Payment Methods Schema Should Be Valid
    And Payment Methods Should Include Types    online    wallet    bnpl
    And All Payment Methods Should Be Clickable
    And Wallet Flag Rule R3 Should Be Valid
    And BNPL Business Rules R4 Through R7 Should Be Valid


S2 BNPL Blocked - Method Not Selectable
    [Documentation]    S2 (rule): BNPL has is_clickable=false.
    ...    Method must be treated as not selectable (R2).
    ...    Options may be present or empty when not clickable (R4).
    [Tags]    S2    required    rule    bnpl    R2    R4

    Given Payment API Is Available At    ${BASE_URL}
    When User Requests Payment Methods With Scenario    bnpl_blocked    ${CELL_NUMBER}
    Then Response Body Should Match Testdata Fixture    bnpl_blocked
    And Response Status Should Be Successful
    And Response Should Contain Payment Methods Array
    And Payment Methods Schema Should Be Valid
    And BNPL Method Should Not Be Selectable Per Rule R2
    And BNPL Options Array Should Be Valid Per Rule R4
    And BNPL Business Rules R4 Through R7 Should Be Valid

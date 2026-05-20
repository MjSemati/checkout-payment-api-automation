*** Settings ***
Documentation    Positive payment API scenarios (P1-P6).
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
P1 Happy Path - All Payment Methods And Rules Valid
    [Documentation]    P1 (positive): online, wallet, and BNPL are present,
    ...    all methods are clickable, and rules R1-R7 pass.
    [Tags]    P1    required    smoke    contract    online    wallet    bnpl    R1    R2    R3    R4    R5    R6    R7

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


P2 BNPL Blocked - Method Not Selectable
    [Documentation]    P2 (rule-positive): BNPL has is_clickable=false.
    ...    Method must be treated as not selectable (R2).
    ...    Options may be present or empty when not clickable (R4).
    [Tags]    P2    required    rule    bnpl    R2    R4

    Given Payment API Is Available At    ${BASE_URL}
    When User Requests Payment Methods With Scenario    bnpl_blocked    ${CELL_NUMBER}
    Then Response Body Should Match Testdata Fixture    bnpl_blocked
    And Response Status Should Be Successful
    And Response Should Contain Payment Methods Array
    And Payment Methods Schema Should Be Valid
    And BNPL Method Should Not Be Selectable Per Rule R2
    And BNPL Options Array Should Be Valid Per Rule R4
    And BNPL Business Rules R4 Through R7 Should Be Valid


P3 Schema Contract - Payment Methods Shape Is Valid
    [Documentation]    P3 (positive): R1 schema contract passes on happy path.
    [Tags]    P3    required    schema    contract    R1

    Given Payment API Is Available At    ${BASE_URL}
    When User Requests Payment Methods With Scenario    happy_path    ${CELL_NUMBER}
    Then Response Body Should Match Testdata Fixture    happy_path
    And Response Status Should Be Successful
    And Response Should Contain Payment Methods Array
    And Payment Methods Schema Should Be Valid


P4 Wallet Rule R3 - Non Wallet Methods Have is_wallet False
    [Documentation]    P4 (positive): wallet flag rule R3 passes on happy path.
    [Tags]    P4    required    wallet    rule    R3

    Given Payment API Is Available At    ${BASE_URL}
    When User Requests Payment Methods With Scenario    happy_path    ${CELL_NUMBER}
    Then Response Body Should Match Testdata Fixture    happy_path
    And Response Status Should Be Successful
    And Response Should Contain Payment Methods Array
    And Wallet Flag Rule R3 Should Be Valid


P5 BNPL Rules R4 Through R7 - Clickable Flow Is Valid
    [Documentation]    P5 (positive): clickable BNPL options satisfy R4-R7.
    [Tags]    P5    required    bnpl    rule    R4    R5    R6    R7

    Given Payment API Is Available At    ${BASE_URL}
    When User Requests Payment Methods With Scenario    happy_path    ${CELL_NUMBER}
    Then Response Body Should Match Testdata Fixture    happy_path
    And Response Status Should Be Successful
    And Response Should Contain Payment Methods Array
    And BNPL Business Rules R4 Through R7 Should Be Valid


P6 BNPL Blocked With Empty Options - Allowed By R2 R4
    [Documentation]    P6 (positive): non-clickable BNPL may have empty options and remain valid.
    [Tags]    P6    required    bnpl    rule    R2    R4

    Given Payment API Is Available At    ${BASE_URL}
    When User Requests Payment Methods With Scenario    bnpl_blocked_empty_options    ${CELL_NUMBER}
    Then Response Body Should Match Testdata Fixture    bnpl_blocked_empty_options
    And Response Status Should Be Successful
    And Response Should Contain Payment Methods Array
    And Payment Methods Schema Should Be Valid
    And BNPL Method Should Not Be Selectable Per Rule R2
    And BNPL Options Array Should Be Valid Per Rule R4
    And BNPL Options Array Should Be Empty
    And BNPL Business Rules R4 Through R7 Should Be Valid

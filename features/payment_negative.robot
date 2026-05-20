*** Settings ***
Documentation    Negative payment API scenarios (S3-S8).
...
...    Business steps (Given/When/Then) live in this file.
...    Technical implementation: steps/ and testdata/scenarios/
...
...    Prerequisites: python3 fake_server/app.py
Resource    ../steps/payment_keywords.robot
Resource    ../steps/testdata_keywords.robot

Default Tags    payment-api    checkout    negative    regression    api    fake-server

*** Variables ***
${BASE_URL}       http://127.0.0.1:8080
${CELL_NUMBER}    09120000000


*** Test Cases ***
S3 Insufficient Credit - BNPL Option Ineligible
    [Documentation]    S3 (negative): BNPL option has credit=0. Violates rule R5.
    [Tags]    S3    required    bnpl    rule    R5

    Given Payment API Is Available At    ${BASE_URL}
    When User Requests Payment Methods With Scenario    insufficient_credit    ${CELL_NUMBER}
    Then Response Body Should Match Testdata Fixture    insufficient_credit
    And Response Status Should Be Successful
    And Response Should Contain Payment Methods Array
    And BNPL Business Rules Should Fail With Error    *Rule R5*


S4 Non Active BNPL Option - Option Ineligible
    [Documentation]    S4 (negative): BNPL option has is_active=false. Violates rule R5.
    [Tags]    S4    required    bnpl    rule    R5

    Given Payment API Is Available At    ${BASE_URL}
    When User Requests Payment Methods With Scenario    inactive_bnpl    ${CELL_NUMBER}
    Then Response Body Should Match Testdata Fixture    inactive_bnpl
    And Response Status Should Be Successful
    And Response Should Contain Payment Methods Array
    And BNPL Business Rules Should Fail With Error    *Rule R5*


S5 Multiple Default BNPL Options - Rule R6 Violation
    [Documentation]    S5 (negative): multiple eligible BNPL options marked default. Violates R6.
    [Tags]    S5    required    bnpl    rule    R6

    Given Payment API Is Available At    ${BASE_URL}
    When User Requests Payment Methods With Scenario    multiple_default    ${CELL_NUMBER}
    Then Response Body Should Match Testdata Fixture    multiple_default
    And Response Status Should Be Successful
    And Response Should Contain Payment Methods Array
    And BNPL Business Rules Should Fail With Error    *Rule R6*


S6 Missing Required Field - Schema Validation Fails
    [Documentation]    S6 (negative): payment method missing required field type. Violates R1.
    [Tags]    S6    required    schema    contract    R1

    Given Payment API Is Available At    ${BASE_URL}
    When User Requests Payment Methods With Scenario    missing_required_field    ${CELL_NUMBER}
    Then Response Body Should Match Testdata Fixture    missing_required_field
    And Response Status Should Be Successful
    And Response Should Contain Payment Methods Array
    And Payment Method Schema Should Fail With Error    *Dictionary does not contain key 'type'*


S7 Wrong Field Type - Type Validation Fails
    [Documentation]    S7 (negative): wrong field types on payment method. Violates R1.
    [Tags]    S7    required    schema    contract    R1

    Given Payment API Is Available At    ${BASE_URL}
    When User Requests Payment Methods With Scenario    wrong_type    ${CELL_NUMBER}
    Then Response Body Should Match Testdata Fixture    wrong_type
    And Response Status Should Be Successful
    And Response Should Contain Payment Methods Array
    And Payment Method Schema Should Fail With Error    *Rule R1*


S8 Non Success HTTP Response - Fail Fast
    [Documentation]    S8 (negative): HTTP 500. Fail fast with clear diagnostics.
    [Tags]    S8    required    smoke    error-handling    fail-fast

    Given Payment API Is Available At    ${BASE_URL}
    When User Requests Payment Methods With Scenario    server_error    ${CELL_NUMBER}
    Then Response Body Should Match Testdata Fixture    server_error
    And HTTP Response Status Should Be    500
    And Request Should Fail Fast On HTTP Error    500

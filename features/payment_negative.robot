*** Settings ***
Documentation    Negative payment API scenarios (N1-N6).
...
...    Business steps (Given/When/Then) live in this file.
...    Technical implementation: steps/ and testdata/scenarios/
...
...    Prerequisites: python3 fake_server/app.py
Resource    ../steps/payment_keywords.robot
Resource    ../steps/testdata_keywords.robot

Default Tags    payment-api    checkout    negative    regression    api    fake-server

*** Test Cases ***
N1 Insufficient Credit - BNPL Option Ineligible
    [Documentation]    N1 (negative): BNPL option has credit=0. Violates rule R5.
    [Tags]    N1    required    bnpl    rule    R5

    Given Checkout Payment API Is Available
    When User Requests Payment Methods With Scenario    insufficient_credit
    Then Response Body Should Match Testdata Fixture    insufficient_credit
    And Response Status Should Be Successful
    And Response Should Contain Payment Methods Array
    And BNPL Business Rules Should Fail With Error    *Rule R5*


N2 Non Active BNPL Option - Option Ineligible
    [Documentation]    N2 (negative): BNPL option has is_active=false. Violates rule R5.
    [Tags]    N2    required    bnpl    rule    R5

    Given Checkout Payment API Is Available
    When User Requests Payment Methods With Scenario    inactive_bnpl
    Then Response Body Should Match Testdata Fixture    inactive_bnpl
    And Response Status Should Be Successful
    And Response Should Contain Payment Methods Array
    And BNPL Business Rules Should Fail With Error    *Rule R5*


N3 Multiple Default BNPL Options - Rule R6 Violation
    [Documentation]    N3 (negative): multiple eligible BNPL options marked default. Violates R6.
    [Tags]    N3    required    bnpl    rule    R6

    Given Checkout Payment API Is Available
    When User Requests Payment Methods With Scenario    multiple_default
    Then Response Body Should Match Testdata Fixture    multiple_default
    And Response Status Should Be Successful
    And Response Should Contain Payment Methods Array
    And BNPL Business Rules Should Fail With Error    *Rule R6*


N4 Missing Required Field - Schema Validation Fails
    [Documentation]    N4 (negative): payment method missing required field type. Violates R1.
    [Tags]    N4    required    schema    contract    R1

    Given Checkout Payment API Is Available
    When User Requests Payment Methods With Scenario    missing_required_field
    Then Response Body Should Match Testdata Fixture    missing_required_field
    And Response Status Should Be Successful
    And Response Should Contain Payment Methods Array
    And Payment Method Schema Should Fail With Error    *Dictionary does not contain key 'type'*


N5 Wrong Field Type - Type Validation Fails
    [Documentation]    N5 (negative): wrong field types on payment methods (same layout as N4). Violates R1.
    [Tags]    N5    required    schema    contract    R1

    Given Checkout Payment API Is Available
    When User Requests Payment Methods With Scenario    wrong_type
    Then Response Body Should Match Testdata Fixture    wrong_type
    And Response Status Should Be Successful
    And Response Should Contain Payment Methods Array
    And Payment Method Schema Should Fail With Error    *Rule R1: id must be int*


N6 Non Success HTTP Response - Fail Fast
    [Documentation]    N6 (negative): HTTP 500. Fail fast with clear diagnostics.
    [Tags]    N6    required    smoke    error-handling    fail-fast

    Given Checkout Payment API Is Available
    When User Requests Payment Methods With Scenario    server_error
    Then Response Body Should Match Testdata Fixture    server_error
    And HTTP Response Status Should Be    500
    And Request Should Fail Fast On HTTP Error    500

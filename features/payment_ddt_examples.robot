*** Settings ***
Documentation    Optional DDT examples using Robot Framework Test Templates.
...    This file is for interview/demo purposes and does not replace BDD suites.
Resource    ../steps/payment_keywords.robot
Resource    ../steps/testdata_keywords.robot

Default Tags    payment-api    checkout    ddt    example    optional

*** Test Cases ***
DDT Positive Rule Coverage
    [Documentation]    Template-driven positive checks across multiple scenarios.
    [Tags]    ddt-positive
    [Template]    DDT Positive Scenario Should Be Valid
    happy_path                  online    wallet    bnpl
    bnpl_blocked                online    wallet    bnpl
    bnpl_blocked_empty_options  online    wallet    bnpl


DDT Negative Rule Coverage
    [Documentation]    Template-driven negative checks for BNPL rule failures.
    [Tags]    ddt-negative
    [Template]    DDT BNPL Rules Should Fail
    insufficient_credit    *Rule R5*
    inactive_bnpl          *Rule R5*
    multiple_default       *Rule R6*
    clickable_bnpl_empty_options    *Rule R4: clickable BNPL must have options*


*** Keywords ***
DDT Positive Scenario Should Be Valid
    [Arguments]    ${scenario}    @{expected_types}
    Given Checkout Payment API Is Available
    When User Requests Payment Methods With Scenario    ${scenario}
    Then Response Body Should Match Testdata Fixture    ${scenario}
    And Response Status Should Be Successful
    And Response Should Contain Payment Methods Array
    And Payment Methods Schema Should Be Valid
    And Payment Methods Should Include Types    @{expected_types}

    # Branch-specific assertions keep the template realistic.
    IF    '${scenario}' == 'happy_path'
        And BNPL Business Rules R4 Through R7 Should Be Valid
    ELSE
        And BNPL Method Should Not Be Selectable Per Rule R2
        And BNPL Options Array Should Be Valid Per Rule R4
        IF    '${scenario}' == 'bnpl_blocked_empty_options'
            And BNPL Options Array Should Be Empty
        END
    END


DDT BNPL Rules Should Fail
    [Arguments]    ${scenario}    ${expected_error}
    Given Checkout Payment API Is Available
    When User Requests Payment Methods With Scenario    ${scenario}
    Then Response Body Should Match Testdata Fixture    ${scenario}
    And Response Status Should Be Successful
    And Response Should Contain Payment Methods Array
    And BNPL Business Rules Should Fail With Error    ${expected_error}

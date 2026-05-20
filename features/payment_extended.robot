*** Settings ***
Documentation    Extended coverage beyond core positive/negative suites.
...
...    Tag "extended" — run with: robot --include extended -d log features/
Resource    ../steps/payment_keywords.robot
Resource    ../steps/testdata_keywords.robot

Default Tags    payment-api    checkout    extended    fake-server

*** Variables ***
${BASE_URL}       http://127.0.0.1:8080
${CELL_NUMBER}    09120000000


*** Test Cases ***
Body Status Error - Fail Fast On Non Success Body Status
    [Documentation]    N6 extension: HTTP 200 but body.status=500 (PDF: body.status != 200).
    [Tags]    N6    error-handling    fail-fast

    Given Payment API Is Available At    ${BASE_URL}
    When User Requests Payment Methods With Scenario    body_error    ${CELL_NUMBER}
    Then Response Body Should Match Testdata Fixture    body_error
    And HTTP Response Status Should Be    200
    And Request Should Fail Fast On Body Status Error    500


Missing Title - Schema Validation Fails
    [Documentation]    N4 extension: payment method missing required field title (PDF: type/title).
    [Tags]    N4    schema    contract    R1

    Given Payment API Is Available At    ${BASE_URL}
    When User Requests Payment Methods With Scenario    missing_title    ${CELL_NUMBER}
    Then Response Body Should Match Testdata Fixture    missing_title
    And Response Status Should Be Successful
    And Response Should Contain Payment Methods Array
    And Payment Method Schema Should Fail With Error    *Dictionary does not contain key 'title'*


Empty Payment Methods Array
    [Documentation]    Scope: empty arrays — payment_methods is empty.
    [Tags]    schema    R1

    Given Payment API Is Available At    ${BASE_URL}
    When User Requests Payment Methods With Scenario    empty_payment_methods    ${CELL_NUMBER}
    Then Response Body Should Match Testdata Fixture    empty_payment_methods
    And Response Status Should Be Successful
    And Response Should Contain Payment Methods Array
    And Payment Methods Array Should Be Empty
    And Payment Methods Schema Should Be Valid


Invalid Price Type - Rule R7 Violation
    [Documentation]    R7 negative: BNPL option has invalid price_type (not CASH_PRICE/CREDIT_PRICE).
    [Tags]    bnpl    rule    R7

    Given Payment API Is Available At    ${BASE_URL}
    When User Requests Payment Methods With Scenario    invalid_price_type    ${CELL_NUMBER}
    Then Response Body Should Match Testdata Fixture    invalid_price_type
    And Response Status Should Be Successful
    And Response Should Contain Payment Methods Array
    And BNPL Business Rules Should Fail With Error    *Rule R7*


BNPL Blocked With Empty Options
    [Documentation]    P6 extension: BNPL not clickable and options array is empty (PDF: options may be empty).
    [Tags]    P6    rule    bnpl    R2    R4

    Given Payment API Is Available At    ${BASE_URL}
    When User Requests Payment Methods With Scenario    bnpl_blocked_empty_options    ${CELL_NUMBER}
    Then Response Body Should Match Testdata Fixture    bnpl_blocked_empty_options
    And Response Status Should Be Successful
    And Response Should Contain Payment Methods Array
    And Payment Methods Schema Should Be Valid
    And BNPL Method Should Not Be Selectable Per Rule R2
    And BNPL Options Array Should Be Valid Per Rule R4
    And BNPL Options Array Should Be Empty


Clickable BNPL With Empty Options - Rule R4 Violation
    [Documentation]    N7 extension: clickable BNPL with empty options must fail Rule R4.
    [Tags]    N7    bnpl    rule    R4

    Given Payment API Is Available At    ${BASE_URL}
    When User Requests Payment Methods With Scenario    clickable_bnpl_empty_options    ${CELL_NUMBER}
    Then Response Body Should Match Testdata Fixture    clickable_bnpl_empty_options
    And Response Status Should Be Successful
    And Response Should Contain Payment Methods Array
    And BNPL Business Rules Should Fail With Error    *Rule R4: clickable BNPL must have options*

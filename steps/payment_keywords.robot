*** Settings ***
Library    Collections
Resource    ../apis/payment_api.robot
Resource    testdata_keywords.robot

*** Variables ***
${BASE_URL}    http://127.0.0.1:8080

*** Keywords ***
# --- Low-level validators (used by Then steps) ---

Validate Response Status Is Successful
    [Arguments]    ${response}    ${response_json}
    Should Be Equal As Integers    ${response.status_code}    200    msg=Expected HTTP 200
    Should Be Equal As Integers    ${response_json}[status]    200    msg=Expected body status 200

Validate Payment Method Schema
    [Arguments]    ${payment_methods}
    FOR    ${method}    IN    @{payment_methods}
        Dictionary Should Contain Key    ${method}    id
        Dictionary Should Contain Key    ${method}    type
        Dictionary Should Contain Key    ${method}    title
        Dictionary Should Contain Key    ${method}    is_clickable
        Dictionary Should Contain Key    ${method}    is_wallet
        Should Be True    type($method["id"]).__name__ == "int"    msg=Rule R1: id must be int
        Should Be True    type($method["type"]).__name__ == "str"    msg=Rule R1: type must be str
        Should Be True    type($method["title"]).__name__ == "str"    msg=Rule R1: title must be str
        Should Be True    type($method["is_clickable"]).__name__ == "bool"    msg=Rule R1: is_clickable must be bool
        Should Be True    type($method["is_wallet"]).__name__ == "bool"    msg=Rule R3: is_wallet must be bool
    END

Validate Wallet Flag Rule R3
    [Arguments]    ${payment_methods}
    FOR    ${method}    IN    @{payment_methods}
        IF    $method["type"] != "wallet"
            Should Be True    $method["is_wallet"] == False    msg=Rule R3: is_wallet must be false when type is not wallet
        END
    END

Validate BNPL Option Schema
    [Arguments]    ${option}
    Dictionary Should Contain Key    ${option}    source_id
    Dictionary Should Contain Key    ${option}    title
    Dictionary Should Contain Key    ${option}    credit
    Dictionary Should Contain Key    ${option}    is_active
    Dictionary Should Contain Key    ${option}    is_default
    Dictionary Should Contain Key    ${option}    price_type
    Should Be True    type($option["source_id"]).__name__ == "int"
    Should Be True    type($option["title"]).__name__ == "str"
    Should Be True    type($option["credit"]).__name__ == "int"
    Should Be True    type($option["is_active"]).__name__ == "bool"
    Should Be True    type($option["is_default"]).__name__ == "bool"
    Should Be True    type($option["price_type"]).__name__ == "str"

Validate BNPL Business Rules
    [Arguments]    ${payment_methods}
    ${bnpl_method}=    Get BNPL Payment Method    ${payment_methods}
    Should Be Equal    ${bnpl_method}[type]    bnpl

    # Rule R4: options must exist and be an array
    Dictionary Should Contain Key    ${bnpl_method}    options
    Should Be True    type($bnpl_method["options"]).__name__ == "list"    msg=Rule R4: options must be an array

    # Rule R2 / R4: non-clickable BNPL — not selectable; strict option rules not required
    IF    $bnpl_method["is_clickable"] == False
        Return From Keyword
    END

    # Clickable BNPL: options must not be empty
    Should Not Be Empty    ${bnpl_method}[options]    msg=Rule R4: clickable BNPL must have options

    ${bnpl_options}=    Set Variable    ${bnpl_method}[options]
    FOR    ${option}    IN    @{bnpl_options}
        Validate BNPL Option Schema    ${option}
        # Rule R5: eligible option requires is_active and credit > 0
        Should Be True    $option["is_active"] == True    msg=Rule R5: BNPL option must be active
        Should Be True    $option["credit"] > 0    msg=Rule R5: BNPL option credit must be greater than 0
        # Rule R7: price_type enum
        Should Be True    $option["price_type"] in ["CASH_PRICE", "CREDIT_PRICE"]    msg=Rule R7: invalid price_type
    END

    # Rule R6: exactly one default among eligible options
    ${default_count}=    Set Variable    ${0}
    FOR    ${option}    IN    @{bnpl_options}
        IF    $option["is_active"] == True and $option["credit"] > 0 and $option["is_default"] == True
            ${default_count}=    Evaluate    ${default_count} + 1
        END
    END
    Should Be Equal As Integers    ${default_count}    1    msg=Rule R6: exactly one eligible BNPL option must be default

Get BNPL Payment Method
    [Arguments]    ${payment_methods}
    FOR    ${method}    IN    @{payment_methods}
        IF    $method["type"] == "bnpl"
            RETURN    ${method}
        END
    END
    Fail    No BNPL payment method found in response

Payment Method With Type Exists
    [Arguments]    ${payment_methods}    ${expected_type}
    FOR    ${method}    IN    @{payment_methods}
        IF    $method["type"] == "${expected_type}"
            RETURN    ${method}
        END
    END
    Fail    No payment method with type '${expected_type}' found in response

Store Response Context
    [Arguments]    ${response}
    Set Test Variable    ${response}
    ${response_json}=    Set Variable    ${response.json()}
    Set Test Variable    ${response_json}
    ${has_payment_methods}=    Run Keyword And Return Status
    ...    Dictionary Should Contain Key    ${response_json}    payment_methods
    IF    ${has_payment_methods}
        ${payment_methods}=    Set Variable    ${response_json}[payment_methods]
        Set Test Variable    ${payment_methods}
    END

# --- BDD steps (use Given/When/Then/And in features; prefixes are stripped by Robot) ---

Payment API Is Available At
    [Arguments]    ${base_url}=${BASE_URL}
    Set Test Variable    ${BASE_URL}    ${base_url}
    Log    Payment API is expected at ${BASE_URL} (start fake_server/app.py)

User Requests Payment Methods With Scenario
    [Arguments]    ${scenario}    ${cell_number}=${EMPTY}
    ${endpoint}=    Build Payment Endpoint    ${scenario}    ${cell_number}
    ${response}=    Get Payment Methods Response    ${BASE_URL}    ${endpoint}
    Store Response Context    ${response}

User Requests Payment Methods With Server Error Scenario
    User Requests Payment Methods With Scenario    server_error

Build Payment Endpoint
    [Arguments]    ${scenario}    ${cell_number}=${EMPTY}
    ${endpoint}=    Set Variable    /payment?scenario=${scenario}
    IF    '${cell_number}' != '${EMPTY}'
        ${endpoint}=    Set Variable    ${endpoint}&CellNumber=${cell_number}
    END
    RETURN    ${endpoint}

Response Status Should Be Successful
    Validate Response Status Is Successful    ${response}    ${response_json}

Response Should Contain Payment Methods Array
    Dictionary Should Contain Key    ${response_json}    payment_methods
    Should Be True    isinstance(${response_json}[payment_methods], list)    msg=payment_methods must be an array

Payment Methods Schema Should Be Valid
    Validate Payment Method Schema    ${payment_methods}

Payment Methods Should Include Types
    [Arguments]    @{expected_types}
    FOR    ${expected_type}    IN    @{expected_types}
        Payment Method With Type Exists    ${payment_methods}    ${expected_type}
    END

All Payment Methods Should Be Clickable
    FOR    ${method}    IN    @{payment_methods}
        Should Be True    $method["is_clickable"] == True    msg=Rule R2: all methods must be clickable on happy path
    END

Wallet Flag Rule R3 Should Be Valid
    Validate Wallet Flag Rule R3    ${payment_methods}

BNPL Business Rules R4 Through R7 Should Be Valid
    Validate BNPL Business Rules    ${payment_methods}

BNPL Method Should Not Be Selectable Per Rule R2
    ${bnpl_method}=    Get BNPL Payment Method    ${payment_methods}
    Should Be Equal    ${bnpl_method}[type]    bnpl
    Should Be Equal    ${bnpl_method}[is_clickable]    ${False}    msg=Rule R2: BNPL must not be selectable when is_clickable is false

BNPL Options Array Should Be Valid Per Rule R4
    ${bnpl_method}=    Get BNPL Payment Method    ${payment_methods}
    Dictionary Should Contain Key    ${bnpl_method}    options
    Should Be True    type($bnpl_method["options"]).__name__ == "list"    msg=Rule R4: options must be an array

BNPL Business Rules Should Fail With Error
    [Arguments]    ${expected_error}
    Run Keyword And Expect Error    ${expected_error}    Validate BNPL Business Rules    ${payment_methods}

Payment Method Schema Should Fail With Error
    [Arguments]    ${expected_error}
    Run Keyword And Expect Error    ${expected_error}    Validate Payment Method Schema    ${payment_methods}

HTTP Response Status Should Be
    [Arguments]    ${expected_status}
    Should Be Equal As Integers    ${response.status_code}    ${expected_status}    msg=Expected HTTP ${expected_status}

Request Should Fail Fast On HTTP Error
    [Arguments]    ${expected_status}=500
    Run Keyword And Expect Error    *${expected_status}*    Validate Response Status Is Successful    ${response}    ${response_json}

Request Should Fail Fast On Body Status Error
    [Arguments]    ${expected_body_status}=500
    Should Be Equal As Integers    ${response.status_code}    200    msg=HTTP should be 200 for body_error scenario
    Run Keyword And Expect Error
    ...    *${expected_body_status}*
    ...    Validate Response Status Is Successful    ${response}    ${response_json}

Payment Methods Array Should Be Empty
    Length Should Be    ${payment_methods}    0    msg=payment_methods array should be empty

BNPL Options Array Should Be Empty
    ${bnpl_method}=    Get BNPL Payment Method    ${payment_methods}
    Length Should Be    ${bnpl_method}[options]    0    msg=Rule R4: BNPL options may be empty when not clickable

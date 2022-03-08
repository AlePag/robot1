*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Archive
Library           RPA.FileSystem
Library           RPA.Dialogs
Library           RPA.Robocorp.Vault

*** Variables ***
${PDF_TEMP_OUTPUT_DIRECTORY}=    ${CURDIR}${/}temp

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Set up directories
    Open the robot order website
    ${orders}=    Get Orders
    Log    Found columns: ${orders.columns}
    FOR    ${row}    IN    @{orders}
        Log    row: ${row}
        Close the annoying modal
        Fill the Form    ${row}
        Preview the robot
        Wait Until Keyword Succeeds
        ...    5x
        ...    1s
        ...    Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}    ${row}[Order number]
    END
    Create a ZIP file of the receipts
    [Teardown]    Cleanup temporary PDF directory

*** Keywords ***
Open the robot order website
    #${url}=    Insert CSV URL From User
    #Open Available Browser    ${url}
    #${secret}=    Get Secret    url
    #Open Available Browser    ${secret}[url1]
    Open Available Browser    https://robotsparebinindustries.com/#/
    Click Link    xpath=//a[@href="#/robot-order"]

Get Orders
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    ${table}=    Read table from CSV    orders.csv
    [Return]    ${table}

Close the annoying modal
    Click Button When Visible    xpath=//*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]

Made Order
    [Arguments]    ${row}
    Fill the Form    ${row}
    Preview the robot
    Submit the order

Fill the Form
    [Arguments]    ${row}
    Wait Until Element Is Visible    id=head
    Select From List By Value    id=head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    css=input.form-control[placeholder^='Enter']    ${row}[Legs]
    Input Text    id=address    ${row}[Address]

Preview the robot
    Click Button    id=preview

Submit the order
    Click Button    id=order
    Click Element When Visible    id:receipt

Store the receipt as a PDF file
    [Arguments]    ${Order number}
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    ${pdf}=    Set Variable    ${PDF_TEMP_OUTPUT_DIRECTORY}${/}receipt_${Order number}.pdf
    Html To Pdf    ${receipt_html}    ${pdf}
    [Return]    ${pdf}

Take a screenshot of the the robot
    [Arguments]    ${Order number}
    ${screenshot_file}=    Set Variable    ${PDF_TEMP_OUTPUT_DIRECTORY}${/}robot-preview-image_${Order number}.png
    Capture Element Screenshot    id=robot-preview-image    ${screenshot_file}
    Click Button    id=order-another
    [Return]    ${screenshot_file}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}    ${Order number}
    ${files}=    Create List
    ...    ${screenshot}
    ...    ${pdf}
    Add Files To PDF    ${files}    ${PDF_TEMP_OUTPUT_DIRECTORY}${/}receipt_${Order number}.pdf

Create a ZIP file of the receipts
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/PDFs.zip
    Archive Folder With Zip
    ...    ${PDF_TEMP_OUTPUT_DIRECTORY}
    ...    ${zip_file_name}

Set up directories
    Create Directory    ${PDF_TEMP_OUTPUT_DIRECTORY}

Cleanup temporary PDF directory
    Close Browser
    Remove Directory    ${PDF_TEMP_OUTPUT_DIRECTORY}    True

Insert CSV URL From User
    Add heading    Insert CSV URL File
    Add text input    message
    ...    label=URL
    ...    placeholder=Enter URL here
    ...    rows=5
    ${result}=    Run dialog
    [Return]    ${result.message}

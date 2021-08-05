*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           OperatingSystem
Library           RPA.Excel.Files
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Archive
Library           RPA.Browser


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order
        Store the receipt as a PDF file    ${row}[Order number]
        Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${row}[Order number]
        Go to order another robot
    END
    Create a ZIP file of the receipts

*** Variables ***
${URL}=    https://robotsparebinindustries.com/#/robot-order


*** Keywords ***
Open the robot order website
    Open Available Browser    ${URL}
    Maximize Browser Window

Get orders
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    ${table}=    Read table from CSV    orders.csv
    Log   Found columns: ${table.columns}
    [Return]    ${table}

 
Close the annoying modal 
    Click Button    xpath://*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]

Fill the form
    [Arguments]    ${row}
    Select From List By Value    xpath://*[@id="head"]    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input     ${row}[Legs]
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[4]/input    ${row}[Address]


Preview the robot
    Click Button    xpath://*[@id="preview"]

Submit the order
    Click Button    xpath://*[@id="order"]
    # Wait Until Keyword Succeeds    10x    1s    Wait Until Page Contains Receipt
    
Store the receipt as a PDF file
    [Arguments]    ${row}
    ${Alert}    Is Element Visible    xpath://*[@id="order-another"]
    IF    '${Alert}' == 'True'
        Wait Until Element Is Visible    xpath://*[@id="order-another"]
        ${receipt_pdf}=    Get Element Attribute    xpath://*[@id="receipt"]   outerHTML
        Html To Pdf    ${receipt_pdf}    ${CURDIR}${/}output${/}Receipt-${row}.pdf
    ELSE
        Log To Console    Order fail, has no receipt
    END

Take a screenshot of the robot 
    [Arguments]    ${row}
    ${Alert}    Is Element Visible    xpath://*[@id="order-another"]
    IF    '${Alert}' == 'True'
        Capture Element Screenshot    xpath://*[@id="robot-preview-image"]    ${CURDIR}${/}output${/}Robot-${row}.png
    ELSE
        Log To Console    Order fail, has no robot
    END
Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${row}
    ${Alert}    Is Element Visible    xpath://*[@id="order-another"]
    IF    '${Alert}' == 'True'
        ${files}=    Create List
            ...    ${CURDIR}${/}output${/}Receipt-${row}.pdf
            ...    ${CURDIR}${/}output${/}Robot-${row}.png
        Add Files To PDF    ${files}    ${CURDIR}${/}output${/}Embed_${row}.pdf 
    ELSE
        Log To Console    Order fail, has no robot
    END

Go to order another robot
    ${Alert}    Is Element Visible    xpath://*[@id="order-another"]
    IF    '${Alert}' == 'True'
        Click Button    xpath://*[@id="order-another"]
    ELSE
        Log To Console    Has Error
        RPA.Browser.Reload Page
    END

Create a ZIP file of the receipts
    @{files}=   List Files In Directory    ${CURDIR}${/}output${/}    *.pdf
    Add To Archive    ${files}    ${CURDIR}${/}output${/}lvt.zip    

### Note: lvt.zip must be created firstly in ${CURDIR}${/}output${/}#############



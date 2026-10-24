@echo off
setlocal enabledelayedexpansion
title Shutdown Confirmation

:pin_entry
:: 1. Run PowerShell script to generate the pure English PIN pop-up UI
for /f "usebackq delims=" %%a in (`powershell -Command "Add-Type -AssemblyName System.Windows.Forms; $form = New-Object System.Windows.Forms.Form; $form.Text = 'Shutdown Confirmation'; $form.Size = New-Object System.Drawing.Size(350,180); $form.StartPosition = 'CenterScreen'; $form.FormBorderStyle = 'FixedDialog'; $form.MaximizeBox = $false; $form.MinimizeBox = $false; $label = New-Object System.Windows.Forms.Label; $label.Text = 'Please enter your 4-digit PIN to shut down:'; $label.Location = New-Object System.Drawing.Point(20,20); $label.Size = New-Object System.Drawing.Size(300,20); $form.Controls.Add($label); $inputBox = New-Object System.Windows.Forms.TextBox; $inputBox.Location = New-Object System.Drawing.Point(20,45); $inputBox.Size = New-Object System.Drawing.Size(290,20); $inputBox.UseSystemPasswordChar = $true; $form.Controls.Add($inputBox); $btnOK = New-Object System.Windows.Forms.Button; $btnOK.Text = 'OK'; $btnOK.Location = New-Object System.Drawing.Point(145,85); $btnOK.Size = New-Object System.Drawing.Size(75,25); $btnOK.DialogResult = [System.Windows.Forms.DialogResult]::OK; $form.AcceptButton = $btnOK; $form.Controls.Add($btnOK); $btnCancel = New-Object System.Windows.Forms.Button; $btnCancel.Text = 'Cancel'; $btnCancel.Location = New-Object System.Drawing.Point(235,85); $btnCancel.Size = New-Object System.Drawing.Size(75,25); $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel; $form.CancelButton = $btnCancel; $form.Controls.Add($btnCancel); $form.ActiveControl = $inputBox; $result = $form.ShowDialog(); if ($result -eq [System.Windows.Forms.DialogResult]::OK) { Write-Output $inputBox.Text } else { Write-Output 'CANCELLED_BY_USER' }"`) do (
    set "entered_pin=%%a"
)

:: Check if the user clicked 'Cancel', closed the window, or left it blank
if "%entered_pin%"=="CANCELLED_BY_USER" goto cancelled
if "%entered_pin%"=="" goto cancelled

:: Check if the entered PIN matches '8845'
if "%entered_pin%"=="8845" (
    goto confirm_shutdown
) else (
    goto failure
)

:confirm_shutdown
:: 2. Run PowerShell to prompt an English confirmation box (Yes/No buttons)
for /l %%i in (1,1,1) do (
    for /f "usebackq delims=" %%b in (`powershell -Command "Add-Type -AssemblyName System.Windows.Forms; $result = [System.Windows.Forms.MessageBox]::Show('Are you sure you want to shutdown?', 'Shutdown Confirmation', [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question); Write-Output $result"`) do (
        set "confirm_choice=%%b"
    )
)

:: If the user chooses anything other than 'Yes' (like clicking No or closing it)
if /i not "%confirm_choice%"=="Yes" goto cancelled
goto success

:cancelled
cls
echo ===========================================
echo             ACTION CANCELLED
echo ===========================================
echo.
:: 10-second countdown loop for cancellation
for /l %%i in (10,-1,1) do (
    cls
    echo ===========================================
    echo             ACTION CANCELLED
    echo ===========================================
    echo.
    echo This window will close automatically in %%i seconds...
    timeout /t 1 >nul
)
exit

:success
:: Trigger the Windows shutdown system countdown (This locks the screen and blocks easy closing)
shutdown /s /t 10 /c "PIN verified. Shutting down in 10 seconds..."

:: Secondary local loop to lock the CMD window and prevent user disruption
:lock_window
cls
echo ===========================================
echo          SHUTDOWN IN PROGRESS
echo ===========================================
echo.
echo The computer is shutting down.
echo Closing this window will not stop the shutdown.
echo.
timeout /t 5 >nul
goto lock_window

:failure
cls
echo ===========================================
echo         ERROR: INCORRECT PIN
echo ===========================================
echo.
echo Access Denied. Please try again.
echo.
pause
goto pin_entry
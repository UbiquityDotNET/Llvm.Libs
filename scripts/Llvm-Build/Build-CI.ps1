$ErrorActionPreference = "Stop"
$InformationPreference = "Continue"

Write-Information "This is a test message - it is supposed to appear in the AppVeyor console log"
Add-AppveyorMessage -Message 'Test Message - it should appear in the Messages tab of the build'
Add-AppveyorCompilationMessage -Message 'Test Compilation Message - It should appear in the console log'


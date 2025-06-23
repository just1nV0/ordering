$CONFIG_FILE = "authorized_device_ids.json"
$APP_NAME_1 = "GulayGulay"
$APP_NAME_0 = "Dev Tool Sparky"
$ANDROID_MANIFEST = "android\app\src\main\AndroidManifest.xml"
$INFO_PLIST = "ios\Runner\Info.plist"
$TARGET_FOLDER = "BUILDS"  

$FIRST_RUN_FLAG = ".first_run_complete"

if ($args.Count -eq 0) {
    $Mode = "release" 
} else {
    $Mode = $args[0]  
}

$isFirstRun = !(Test-Path $FIRST_RUN_FLAG)

if (!(Test-Path $CONFIG_FILE)) {
    Write-Host "Configuration file $CONFIG_FILE not found!"
    exit 1
}

$JSON_CONTENT = Get-Content $CONFIG_FILE | ConvertFrom-Json
$APP_ACTION = $JSON_CONTENT.app_action

if ($null -eq $APP_ACTION) {
    Write-Host "Failed to parse JSON or app_action not found."
    exit 1
}

Write-Host "Parsed app_action: " -NoNewline -ForegroundColor White
Write-Host $APP_ACTION -ForegroundColor Blue

if ($APP_ACTION -eq 1) {
    $SELECTED_APP_NAME = $APP_NAME_1
} else {
    $SELECTED_APP_NAME = $APP_NAME_0
}

Write-Host "Selected app name: " -NoNewline -ForegroundColor White
Write-Host $SELECTED_APP_NAME -ForegroundColor Green

if (Test-Path $ANDROID_MANIFEST) {
    Write-Host "Updating Android app name in $ANDROID_MANIFEST"
    (Get-Content $ANDROID_MANIFEST) -replace 'android:label="[^"]*"', "android:label=`"$SELECTED_APP_NAME`"" | Set-Content $ANDROID_MANIFEST
} else {
    Write-Host "AndroidManifest.xml not found at $ANDROID_MANIFEST"
    exit 1
}

if (Test-Path $INFO_PLIST) {
    Write-Host "Updating iOS app name in $INFO_PLIST"
    Write-Host "Warning: PlistBuddy is not available on Windows. Manual update may be required for iOS."
    Write-Host "Please update the CFBundleDisplayName in $INFO_PLIST to '$SELECTED_APP_NAME'"
} else {
    Write-Host "Info.plist not found at $INFO_PLIST"
    exit 1
}

Write-Host "App name updated to '$SELECTED_APP_NAME' based on app_action: $APP_ACTION"

Write-Host "Building or running the app based on the provided mode..."

if ($isFirstRun) {
    Write-Host "First run detected. Executing 'flutter clean'..."
    flutter clean
    New-Item -ItemType File -Path $FIRST_RUN_FLAG | Out-Null
} else {
    Write-Host "Not the first run. Skipping 'flutter clean'..."
}

if ($Mode -eq "--release") {
    Write-Host "Release mode detected. Running flutter build apk --release..." -ForegroundColor Yellow
    flutter build apk --release
} elseif ($Mode -eq "--dev") {
    Write-Host "Dev mode detected. Running flutter run..." -ForegroundColor Yellow
    flutter run
} else {
    Write-Host "Release mode detected. Running flutter build apk --release..." -ForegroundColor Yellow
    flutter build apk --release
}

$SOURCE_APK = "build\app\outputs\flutter-apk\app-release.apk"
$DESTINATION_APK = "$TARGET_FOLDER\$SELECTED_APP_NAME.apk"

if (!(Test-Path $TARGET_FOLDER)) {
    New-Item -ItemType Directory -Path $TARGET_FOLDER | Out-Null
}

if (Test-Path $SOURCE_APK) {
    Clear-Host
    Write-Host ""
    Move-Item -Path $SOURCE_APK -Destination $DESTINATION_APK -Force
    Write-Host "====================================================================================" -ForegroundColor Green
    Write-Host "Build process completed. The " -NoNewline -ForegroundColor White
    Write-Host $DESTINATION_APK -NoNewline -ForegroundColor Green
    Write-Host " is now in the '" -NoNewline -ForegroundColor White
    Write-Host $TARGET_FOLDER -NoNewline -ForegroundColor Green
    Write-Host "' folder." -ForegroundColor White
    Write-Host "====================================================================================" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "==========================================================================" -ForegroundColor Red
    Write-Host "Error: Built APK not found at " -NoNewline -ForegroundColor White
    Write-Host $SOURCE_APK  -ForegroundColor Red
    Write-Host "==========================================================================" -ForegroundColor Red
    exit 1
}
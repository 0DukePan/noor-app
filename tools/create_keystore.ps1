# Creates the release signing keystore (android/app/noor-release.jks) and the
# android/key.properties file consumed by android/app/build.gradle.
#
# Run once on the machine that will publish the app:
#   powershell -ExecutionPolicy Bypass -File tools\create_keystore.ps1
#
# IMPORTANT: back up android/app/noor-release.jks and android/key.properties
# somewhere safe. Losing the keystore means you can never update the app on
# Google Play / App Store with the same identity.

$ErrorActionPreference = 'Stop'

$keytool = Get-Command keytool -ErrorAction SilentlyContinue
if (-not $keytool) {
  $javaHome = $env:JAVA_HOME
  if ($javaHome -and (Test-Path (Join-Path $javaHome 'bin\keytool.exe'))) {
    $keytool = Join-Path $javaHome 'bin\keytool.exe'
  } else {
    throw "keytool not found. Install the JDK (or set JAVA_HOME) and try again."
  }
}

$root = Split-Path -Parent $PSScriptRoot
$keystoreDir = Join-Path $root 'android\app'
$keystorePath = Join-Path $keystoreDir 'noor-release.jks'
$propsPath = Join-Path $root 'android\key.properties'

if (Test-Path $keystorePath) {
  throw "Keystore already exists at $keystorePath — delete it first if you really want to regenerate (this would orphan any published app)."
}

Write-Host ''
Write-Host '== Noor release keystore ==' -ForegroundColor Cyan
Write-Host 'Choose a strong password (min 6 chars) and remember it.'
$storePass = Read-Host -AsSecureString 'Keystore password'
$keyPass = Read-Host -AsSecureString 'Key password (can be the same)'

function Get-Plain([System.Security.SecureString]$s) {
  [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($s))
}

$storePassPlain = Get-Plain $storePass
$keyPassPlain = Get-Plain $keyPass
if ($storePassPlain.Length -lt 6 -or $keyPassPlain.Length -lt 6) {
  throw 'Passwords must be at least 6 characters.'
}
if ($storePassPlain -ne $keyPassPlain) {
  Write-Host 'Using different store/key passwords is fine, but both are required below.'
}

$alias = 'noor'
Write-Host ''
Write-Host 'The keystore is generated with a 10000-day validity, which covers the'
Write-Host 'entire expected lifetime of the app. The alias is fixed to "noor".'

$args = @(
  '-genkeypair', '-v',
  '-keystore', $keystorePath,
  '-alias', $alias,
  '-keyalg', 'RSA',
  '-keysize', '4096',
  '-validity', '10000',
  '-storepass', $storePassPlain,
  '-keypass', $keyPassPlain,
  '-dname', 'CN=Noor, OU=Noor, O=Noor, L=Unknown, ST=Unknown, C=SA'
)

& $keytool @args
if ($LASTEXITCODE -ne 0) { throw 'keytool failed.' }

$props = @(
  "storePassword=$storePassPlain",
  "keyPassword=$keyPassPlain",
  "keyAlias=$alias",
  'storeFile=../app/noor-release.jks'
)
Set-Content -Path $propsPath -Value $props -Encoding ascii

Write-Host ''
Write-Host "Keystore:  $keystorePath" -ForegroundColor Green
Write-Host "Config:    $propsPath" -ForegroundColor Green
Write-Host ''
Write-Host 'NEXT: push the app to GitHub and the CI will sign the release AAB'
Write-Host 'with these secrets (set them in repo Settings > Secrets and variables > Actions):'
Write-Host '  KEYSTORE_BASE64   base64 of noor-release.jks:'
Write-Host '    [Convert]::ToBase64String([IO.File]::ReadAllBytes("D:\Downloads\noor-app-main\noor-app-main\android\app\noor-release.jks"))'
Write-Host '  KEYSTORE_PASSWORD the store password'
Write-Host '  KEY_PASSWORD      the key password'
Write-Host '  KEY_ALIAS         noor'
Write-Host ''
Write-Host 'KEEP THESE PASSWORDS AND THE JKS FILE SAFE — they cannot be recovered.' -ForegroundColor Yellow

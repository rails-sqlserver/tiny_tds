$gemVersion = (Get-Content VERSION).Trim()
$gemToUnpack = "./tiny_tds-$gemVersion-$env:RUBY_ARCHITECTURE.gem"

Write-Host "Looking to unpack $gemToUnpack"
gem unpack --target ./tmp "$gemToUnpack"

# Restore precompiled code
$source = (Resolve-Path ".\tmp\tiny_tds-$gemVersion-$env:RUBY_ARCHITECTURE\lib\tiny_tds").Path
$destination = (Resolve-Path ".\lib\tiny_tds").Path
Get-ChildItem $source -Recurse -Exclude "*.rb" | Copy-Item -Destination {Join-Path $destination $_.FullName.Substring($source.length)}

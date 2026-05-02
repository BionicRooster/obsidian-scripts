$errors = $null
$tokens = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile(
    'C:\Users\awt\obsidian_maintenance.ps1',
    [ref]$tokens,
    [ref]$errors
)
if ($errors.Count -eq 0) {
    Write-Output "Parse OK - no syntax errors"
} else {
    Write-Output "Parse ERRORS: $($errors.Count)"
    foreach ($e in $errors) {
        Write-Output "  Line $($e.Extent.StartLineNumber): $($e.Message)"
    }
}

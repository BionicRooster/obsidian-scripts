# Verify orphan moves completed successfully
$bahai = "D:\Obsidian\Main\01\Bah" + [char]0x00e1 + "'" + [char]0x00ed

$checks = @(
    @{ Path = "$bahai\Five Ways to Optimize the Powerful Tool of Baha'i Consultation.md"; Label = "Five Ways -> Bahai" },
    @{ Path = "D:\Obsidian\Main\01\Home\How a `$300 Amish Earth Tube System Can Keep Your Home Cool at 55" + [char]0x00B0 + "F Year-Round Without Electricity.md"; Label = "Amish Earth Tube -> Home" },
    @{ Path = "D:\Obsidian\Main\01\Social\Two Paths.md"; Label = "Two Paths -> Social" },
    @{ Path = "D:\Obsidian\Main\01\Genealogy\Searching for Lee.md"; Label = "Searching for Lee -> Genealogy" },
    @{ Path = "D:\Obsidian\Main\01\Bah" + [char]0x00e1 + "'" + [char]0x00ed + "\Be182 Year in Review.md"; Label = "BE182 in Bahai (unchanged)" },
    @{ Path = "D:\Obsidian\Main\Email Contacts.md"; Label = "Email Contacts in root (unchanged)" }
)

foreach ($c in $checks) {
    if (Test-Path -LiteralPath $c.Path) {
        Write-Host "OK  : $($c.Label)"
    } else {
        Write-Host "MISS: $($c.Label) -- $($c.Path)"
    }
}

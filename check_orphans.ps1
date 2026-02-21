$orphans = Get-Content 'C:\Users\awt\orphan_list.json' | ConvertFrom-Json

# Files that matched our grep search for social issues keywords
$matches = @(
    '11 - Evernote\The Powerful Message.md',
    '11 - Evernote\New Documentary Film.md',
    '11 - Evernote\19th Century Religio.md',
    "12 - OneNote\Bahá'í\Bahá'u'lláh Birthday.md",
    "12 - OneNote\Bahá'í\The Religious Missio.md",
    "12 - OneNote\Bahá'í\Losing my religion f.md",
    "12 - OneNote\Bahá'í\IranWire  A Living S.md",
    "12 - OneNote\Bahá'í\Levels of Racism Vis.md",
    "12 - OneNote\Bahá'í\Blind to prejudice.md",
    "Clippings\A Woman's Place At the Peace Table.md",
    '11 - Evernote\Tibetan Buddhism.md',
    '11 - Evernote\Global Religion in the 21st Century.md',
    "11 - Evernote\Holly Near - Holly and Ronnie's Timeline.md",
    '11 - Evernote\Celebrating Ayyam-I-Ha.md',
    '11 - Evernote\Bernie Sanders Where the Democrats Go From Here.md',
    '11 - Evernote\Can computers be racist.md',
    "11 - Evernote\What's Up With Muslims and Dogs.md",
    '11 - Evernote\Walking is a Basic H.md',
    "11 - Evernote\The Titanic's Forgot.md",
    '11 - Evernote\The tyranny of a traffic Ticket.md',
    '11 - Evernote\The Woman Who Helped.md',
    "11 - Evernote\Ridvan – The Greates.md",
    '11 - Evernote\Mr. President, on be.md',
    '11 - Evernote\Local religious comm.md',
    '11 - Evernote\HP Retiree  Dave Pac.md',
    '11 - Evernote\An Open Letter to E-Book Retailers.md',
    '11 - Evernote\An Oral History of Laurel Canyon.md',
    '20 - Permanent Notes\Universal House of J.md',
    '20 - Permanent Notes\Trump and Brexit are.md',
    '20 - Permanent Notes\The Promulgation of .md',
    '20 - Permanent Notes\Major causes of disunity.md',
    "20 - Permanent Notes\How Houston's rich k.md",
    '20 - Permanent Notes\Discussion of NLP Me.md',
    '20 - Permanent Notes\Bullet Point Summary.md',
    "20 - Permanent Notes\Bahá'ís Refrain from.md",
    '12 - OneNote\Personal (Web)\Misc\What White Supremaci.md',
    '12 - OneNote\Personal (Web)\Misc\Losing my religion f.md',
    "12 - OneNote\Bahá'í\Remembering the Mart.md",
    "12 - OneNote\Bahá'í\Shoghi Effendi on Ra.md",
    "12 - OneNote\Bahá'í\Christianity and the.md",
    "12 - OneNote\Bahá'í\Baha'i Coherence 19t.md",
    "12 - OneNote\Bahá'í\A response to why do.md",
    "11 - Evernote\Politics\Michael Moore's to do list for a revolution.md",
    '11 - Evernote\Politics\America Has Never Be.md',
    '11 - Evernote\Entertainment\Star Trek - a critique of Robert Heinlein.md',
    '20 - Permanent Notes\Time Line Therapy.md',
    'Clippings\The Destiny of America.md',
    'Clippings\How to Promote Unity.md',
    '12 - OneNote\Personal (Web)\MiscStuff\How to Be a Better A.md',
    'Clippings\Shoghi effendi on un.md',
    '20 - Permanent Notes\The Women of Rohan.md',
    "20 - Permanent Notes\America's four stories.md",
    '20 - Permanent Notes\All Prophets are Equal.md',
    '11 - Evernote\Politics\Noam Chomsky on Whet.md',
    '10 - Clippings\How Japanese Kiyomer.md',
    '09 - Kindle Clippings\McGhee-The Sum of Us.md',
    "12 - OneNote\Bahá'í\Muhammad Ali on Unit.md",
    'Clippings\Pluralistic By all m.md',
    'Clippings\Leave Your War at th.md',
    '20 - Permanent Notes\Protocols for Effect.md',
    '20 - Permanent Notes\My Color Blindness.md',
    '20 - Permanent Notes\My Color Blindness 1.md',
    "20 - Permanent Notes\Inside America's Aus.md",
    '12 - OneNote\Personal (Web)\MiscStuff\Gini Coefficient by .md',
    "12 - OneNote\Bahá'í\On Jimmy Carter's Loss of Faith.md",
    "12 - OneNote\Bahá'í\10 Quotes From an Og.md",
    "11 - Evernote\Politics\Charlie Chaplin's Sp.md",
    '10 - Clippings\How to deconstruct racism.md',
    '10 - Clippings\We need to talk about an injustice.md',
    '10 - Clippings\A Juneteenth Convers.md',
    '09 - Kindle Clippings\LICSW Resmaa Menakem.md',
    '09 - Kindle Clippings\LICSW Resmaa Menakem-My Grandmothers Hands.md',
    '09 - Kindle Clippings\Blume-Fallout.md'
)

$orphanMatches = @()
foreach ($m in $matches) {
    if ($orphans -contains $m) {
        $orphanMatches += $m
    }
}

Write-Output "Found $($orphanMatches.Count) orphans matching Social Issues & Unity:"
Write-Output ""
$i = 1
foreach ($o in $orphanMatches) {
    Write-Output "$i. $o"
    $i++
}

# Restore NLP Forum file with properly formatted content
# Content reconstructed from the single-line version captured before accidental zeroing

$dir = 'D:\Obsidian\Main\01\NLP'
$file = Get-ChildItem -Path $dir -Filter '*NLP Forum*Contest*' | Select-Object -First 1

if ($null -eq $file) {
    Write-Output "File not found"
    exit
}

$content = @'
---
title: "NLP Forum — Contest World Rocked! (December 1994)"
source: "CompuServe AI Expert+ Forum, NeuroLinguistic Section"
created: 1994-12
description: "Forum thread in which contest sponsor confesses to fraud and offers prizes as penance."
tags:
  - NLP
  - CompuServe
  - ForumArchive
nav: "[[01/NLP]] | [[MOC - NLP & Psychology]]"
---

[[01/NLP]] | [[MOC - NLP & Psychology]]

*Archived forum thread from the CompuServe AI Expert+ Forum, NeuroLinguistic Section — December 1994.*

**Participants:** Nelson Zink, Peter Wrycza

**Topics:** Discussion of Contest World Rocked! in the context of NLP practice.

---

## Contest World Rocked! *(December 1994)*

### Message 1

**From:** Nelson Zink
**To:** All
**Date:** 07 Dec 1994

TODAY IT HAS BEEN REPORTED THAT A CERTAIN ONLINE CONTEST STANDS ACCUSED OF FRAUD. THE CONTEST'S SPONSOR STATES:

"Alas, it's true. I was hoping for huge bribes to amass partial payment for a joint English-French hair transformation seminar. That's all I wanted, just to get into the hair business. Is that so bad? Unfortunately, the bribes were not forthcoming and the contest's judge was stricken by sudden ethical pangs. I am guilty of the accusations."

SAID SPONSOR CONTINUES:

"I'm sorry and hope to never be tempted by the hair business again. I've learned my lesson. As an act of penance and remorse I will send prizes to the first three postal addresses received by me. If I can make someone's Christmas a little brighter it will help remove my shame."

FURTHER DEVELOPMENTS WHICH WARRANT ATTENTION WILL BE REPORTED.

NZN

### Message 2

**From:** Peter Wrycza
**To:** Nelson Zink
**Date:** 08 Dec 1994

The scally, needs a good wigging if you ask me.

---

## Related Notes

- [[Time Line Therapy]]
- [[NLP World]]
'@

[System.IO.File]::WriteAllText($file.FullName, $content, [System.Text.Encoding]::UTF8)
Write-Output "Restored: $($file.FullName)"

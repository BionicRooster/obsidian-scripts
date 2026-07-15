"""Write clean version of the Kintsugi note to 01/Japan."""
import os, glob

# Remove the garbled file first
matches = glob.glob('C:/Users/awt/Sync/Obsidian/01/Japan/*Kintsugi*')
for f in matches:
    os.remove(f)

content = """\
---
title: "Trevor Noah Explains How Kintsugi Helped Him Overcome Life's Tragedies"
source: "https://www.openculture.com/2026/01/trevor-noah-explains-how-kintsugi-helped-him-overcome-lifes-tragedies.html"
author:
  - "[[Colin Marshall]]"
published: 2026-01-09
created: 2026-01-09
description: "Trevor Noah discusses kintsugi — the Japanese art of repairing broken pottery with gold — as a metaphor for resilience and finding beauty in one's own cracks, drawing on his own experiences of trauma."
tags:
  - Kintsugi
  - Japan
  - JapaneseCulture
  - TrevorNoah
  - Resilience
  - Clippings
nav: "[[01/Japan]] | [[MOC - Japan & Japanese Culture]]"
---

[[01/Japan]] | [[MOC - Japan & Japanese Culture]]

Trevor Noah ended his stint as the host of *The Daily Show* a little over three years ago, but he's made himself into another kind of pop-cultural presence since then. In evidence, we have [his appearance](https://www.youtube.com/watch?v=FsztuzyXdhY&t=8799s) on the popular podcast and YouTube show *Diary of a CEO.* For more than two and a half hours, Noah discusses with host Steven Bartlett (who, like Noah, also happens to be African-born with mixed parentage) his reasons for quitting that political-news-comedy TV institution, his struggles with depression, and the time his stepfather shot his mother in the head. She lived, owing to the miraculously unlikely trajectory of the bullet, but that didn't stop the experience from becoming what Noah describes as the worst of his life.

Discussing all this brings to his mind the Japanese art of *[kintsugi](https://en.wikipedia.org/wiki/Kintsugi)* (previously featured on Open Culture). "It's a practice of repairing pottery and ceramics that have broken," Noah explains. "What happens is, you break a plate, or you break a vase or something," and "they put it back together, these artisans who do it. But they don't just glue it back together — they glue it back together and they sort of adorn it with a golden binding. And what you get is an object that is somehow more beautiful than before it was broken."

Kintsugi struck him as "one of the most beautiful concepts, and a different way to think about being 'fixed' or 'overcoming'"; it wasn't "the idea that we are perfect, the way we were before something happened to us, but rather, it is that we get to wear our cracks with a new type of pride, and a new type of beauty."

Noah would hardly be the only person to see in these reconstituted ceramic vessels with their gleaming kintsugi seams a metaphor for himself. Like more than a few public figures in the West, he's been willing to discuss the vicissitudes of his life in detail, and even use them for material in work like his stand-up comedy and his memoir *Born a Crime.* But it is unusual, in a chat like this with millions of viewers, to hear reference made to a half-millennium-old Japanese form of pottery repair. That possibility, of course, is central to the appeal of long-form interview podcasts, whose conversations have the time and space to go far down unexpected paths. *The Daily Show* may deliver more laughs per minute, but given its format's time constraints, kintsugi-type talk is no doubt the first thing to get edited out.

*By Colin Marshall, based in Seoul.*

---

## Related Notes

- [[MOC - Japan & Japanese Culture]]
- [[Mogi-The Way of Nagomi]]
- [[Inemuri, the Japanese Art of Taking Power Naps]]
"""

dst = "C:/Users/awt/Sync/Obsidian/01/Japan/Trevor Noah Explains How Kintsugi Helped Him Overcome Life's Tragedies.md"
with open(dst, 'w', encoding='utf-8') as f:
    f.write(content)

print(f"Written: {dst}")

local prompts = {}

prompts.section_summarization = [[You are extracting information for a later cover design process.

This is only one section of a larger story.

Do NOT attempt to design a cover.
Do NOT decide what should appear on the cover.
Do NOT write a summary.

Extract only information that may be useful when creating a cover after all story sections have been analyzed.

Return:

GENRE:
- up to 5 items

SETTING:
- locations
- environments
- time period

CHARACTERS:
- names
- physical descriptions
- distinctive visual traits

CREATURES:
- notable creatures

OBJECTS:
- important recurring items

VISUAL MOTIFS:
- recurring imagery
- symbols
- repeated visual elements

THEMES:
- major themes

MOOD:
- emotional tone

COLORS:
- colors strongly associated with scenes or imagery

MEMORABLE VISUAL SCENES:
- 3-10 visually striking moments

CONFIDENCE:
- how central each item appears to be

]]

prompts.combine_summaries = [[Take the common portions from the following text and produce a single simplified list of information:

]]

prompts.cover_brief = [[Generate a cover brief from the following:

]]

prompts.for_gemini = [[

Generate an ebook cover using the following cover brief. It should be a flat graphic design file, with no artifacts of a physical object. The aspect ratio of an ebook is tall, not wide. The title and author should only appear once on the cover. It must be suitable for printing. Do not include the word "by" on the cover. An underscore in the title should be replaced with a colon, but not hyphens or as a separator between the title and author. The author is separated from the title by the last hyphen on the line showing the title and author.

]]

return prompts

## Usage
1. Use a tool like [audiobook-creator](https://github.com/prakharsr/audiobook-creator) to extract the text of an audiobook.
2. Place it in `extracted_texts/TITLE by AUTHOR.txt`.
3. Run `make_cover_briefs.lua`. (Relies on Ollama and `gemma4:12b-mlx` and requires at least a Mac mini M4 base model.)
4. Cover briefs will be placed in `cover_briefs`.
5. A prompt ready to paste directly into Gemini will be in `for_gemini`. An extra border is prompted for to make cropping easy to remove the Gemini watermark.

### Gemini Issues
None of this works unless you disable Gemini's personalization/memory, because it pollutes context extremely badly and will randomly add elements and rejections from different conversations everywhere.

If Gemini rejects the prompt, adding "Remove any elements that may go against guidelines before generating the image." to the opening paragraph can fix that issue.
- This suddenly got a lot less effective. I recommend instead telling it to rewrite the prompt and then in a separate conversation, use that instead.

Gemini is really bad about adding hardcover seams. Despite being instructed not to, it shows up sometimes. More strong prompting breaks other features, so the best way to deal with it is to request its removal after the initial image is generated.

The local model sometimes completely forgets critical details of characters, so it's important you have some familiarity with the work before running the generator to check accuracy.

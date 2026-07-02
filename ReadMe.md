# llm-covers
A simple tool for using local LLMs to generate cover briefs for ebooks.

## Requirements
- A Mac mini M4 base model (original version) or better M-series computer
- Ollama and `gemma4:12b-mlx`
- LuaJIT

## Usage
1. Use a tool like [audiobook-creator](https://github.com/prakharsr/audiobook-creator) to extract the text of an audiobook.
2. Place it in `extracted_texts/TITLE by AUTHOR.txt`. (The format of this doesn't matter except that the file name sans extension will be used in the output.)
3. Run `make_cover_briefs.lua`.
4. Cover briefs will be placed in `cover_briefs`.
5. A prompt ready to paste directly into Gemini will be in `for_gemini`. An extra border is prompted for to make cropping easy to remove the Gemini watermark. (There are other small changes to increase likelihood of Gemini following the prompt correctly and making a good output.)

### Gemini Issues
None of this works unless you **disable Gemini's personalization/memory**, because it pollutes context
extremely badly and will randomly add elements and rejections from different conversations everywhere.

If Gemini rejects the prompt, adding <code id="d2651e">Remove any elements that may go against guidelines before generating the image.</code>
<button onclick="navigator.clipboard.writeText(d2651e.textContent)">⧉</button>
to the opening paragraph can fix that issue.
- This suddenly got a lot less effective. I recommend instead telling it to rewrite the prompt and then
  in a separate conversation, use that instead. I also recommend one retry before modifying it.

Gemini is really bad about adding hardcover seams. Despite being instructed not to, it shows up sometimes.
More strong prompting breaks other requested features, so the best way to deal with it is to request its
removal after the initial image is generated.

The local model sometimes completely forgets critical details of characters,
so it's important you have some familiarity with the work before running the generator
to check accuracy.

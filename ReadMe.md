## Usage
1. Use a tool like [audiobook-creator](https://github.com/prakharsr/audiobook-creator) to extract the text of an audiobook.
2. Place it in `extracted_texts/TITLE by AUTHOR.txt`.
3. Run `make_cover_briefs.lua`. (Relies on Ollama and `gemma4:12b-mlx` and requires at least a Mac mini M4 base model.)
4. Cover briefs will be placed in `cover_briefs`.
5. A prompt ready to paste directly into Gemini will be in `for_gemini`. An extra border is prompted for to make cropping easy to remove the Gemini watermark.

If Gemini rejects the prompt, adding "Remove any elements that may go against guidelines before generating the image." to the opening paragraph can fix that issue.

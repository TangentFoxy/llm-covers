# llm-covers
A simple tool for using local LLMs to generate cover briefs for ebooks.

## Requirements
- A Mac mini M4 base model (original version) or better M-series computer
- Ollama and `gemma4:12b-mlx`
- LuaJIT
- calibre

## Usage
1. Create `config.json` if necessary (see format below).
2. Run `make_cover_briefs.lua` once to create necessary directories.
3. Put ebooks in `raw_ebooks`.
4. Run `make_cover_briefs.lua`

Cover briefs will be placed in `cover_briefs`. A prompt ready to paste directly
into Gemini will be in `for_gemini`. An extra border is prompted for to make
cropping easy to remove the Gemini watermark. (There are other small changes to
increase likelihood of Gemini following the prompt correctly and making a good
output.)

### Config file format
```json
{
  "llm_covers": {
    "calibre_location": "/Applications/calibre.app",
    "default_model": "gemma4:12b-mlx",
    "maximum_bytes": 40000
  }
}
```

The above are the default settings. If you need something different, you only
need to specify the changes. (There is a `config.json.example` file equivalent
to the above.)

### Gemini Issues
None of this works unless you **disable Gemini's personalization/memory**,
because it pollutes context extremely badly and will randomly add elements and
rejections from different conversations everywhere.

If Gemini rejects the prompt, adding
<code id="d2651e">Remove any elements that may go against guidelines before generating the image.</code>
<button onclick="navigator.clipboard.writeText(d2651e.textContent)">⧉</button>
to the opening paragraph can fix that issue.
- This suddenly got a lot less effective. I recommend instead telling it to
  rewrite the prompt and then in a separate conversation, use that instead. I
  also recommend one retry before modifying it.

Gemini is really bad about adding hardcover seams. Despite being instructed not
to, it shows up sometimes. More strong prompting breaks other requested
features, so the best way to deal with it is to request its removal after the
initial image is generated.

The local model sometimes completely forgets critical details of characters, so
it's important you have some familiarity with the work before running the
generator to check accuracy.

## Tasks
- [ ] Add timestamps to when a prompt is sent.
- [ ] Specify ETA when sending a prompt (use numbers from current estimator depending on length). (Show as end time as well as relative time.)
- [ ] option to delete input files or intermediate files at end of each major operation segment (or after its finisher..)
- [ ] Allow specifying a filter on what to process
- [ ] Allow changing the maximum bytes per prompt dynamically (run smaller while I'm doing other things, run full while I'm asleep)
- [ ] `argparse` + ability to
  - [ ] only convert ebooks or
  - [ ] only generate cover briefs or
  - [ ] only generate single pass cover briefs or
  - [ ] list how many are left only

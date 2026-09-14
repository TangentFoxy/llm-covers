# llm-covers
Makes placeholder cover briefs for ebooks.

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
into Gemini will be in `for_gemini`.

The local model sometimes completely forgets critical details of characters, so
it's important you have some familiarity with the work before running the
generator to check accuracy.

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

If you are able to use Gemini Flash or Flash-Lite, it works far better than Pro.
Pro tends to invent additional details, refuse to respond, fail to respond, or
make modifications you didn't ask for. I genuinely cannot understand how it is
*so much worse* at this.

Gemini is really bad about adding hardcover seams. Despite being instructed not
to, it shows up often. More strong prompting breaks other requested
features, so the best way to deal with it is to request its removal after the
initial image is generated.

If Gemini rejects the prompt, adding
<code id="d2651e">Remove any elements that may go against guidelines before generating the image.</code>
<button onclick="navigator.clipboard.writeText(d2651e.textContent)">⧉</button>
to the opening paragraph can *sometimes* fix that issue.
- Telling it to rewrite the prompt and then using *that* in a separate
  conversation tends to work better.
- I typically just re-send it repeatedly, as it's easier and eventually works
  most of the time.

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
- [x] I have an item with over 300 parts in it. Another level of compression needs to be added!
- [ ] Change Gemini prompt because it is *obsessed* with putting colons EVERYWHERE.

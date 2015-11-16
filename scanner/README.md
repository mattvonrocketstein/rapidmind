ABOUT
======
My first humble elixir project.  
This is a command line utility that scans subreddits for interesting content.
It works like this:

0. edit rules.json and replace with things of interest to you
1. download and parse the page for the given subreddit
2. download all pages mentioned in the top links
3. parse those pages for regexes mentioned in `rules.json`

USAGE
======

You'll need elixir (that's `brew install elixir` on OSX or `sudo apt-get install elixir` on ubuntu).
Run `mix escript.build` to compile the command line program, then invoke it

    $ mix escript.build
    $ ./scanner_cli --reddit=programming --rules=rules.json

REFERENCES
===========

* [OptionParser Docs](http://elixir-lang.org/docs/stable/elixir/OptionParser.html)

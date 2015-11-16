ABOUT
======
My first humble elixir project.

`rasp` is a command line scraper that scans subreddits for interesting content.

Rasp works like this:

1. download and parse the main page for the given subreddit
2. download all pages mentioned in the top links for that subreddit
3. parse those pages for regexes mentioned in `rules.json`

USAGE
======

First if your interests are different than mine (and they probably are) change `rules.json` to mention stuff that interests you.

Next you'll need elixir (that's `brew install elixir` on OSX or `sudo apt-get install elixir` on ubuntu).

To compile the command line program, run:

    $ mix escript.build

Required arguments are like so:

    $ ./rasp --reddit=programming --rules=rules.json


REFERENCES
===========

* HTML parsing via [Floki](https://github.com/philss/floki)
* Option parsing via [OptionParser](http://elixir-lang.org/docs/stable/elixir/OptionParser.html)
* URL downloads via [HTTPoison](https://github.com/edgurgel/httpoison)
* JSON encoding/decoding via [https://github.com/devinus/poison](Poison)

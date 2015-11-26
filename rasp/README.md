## About

This is my first humble elixir project.

`rasp` is a command line scraper that scans webpages for interesting content.  It works with any webpage but has separate configuration options specifically for scanning subreddits.


##Usage

First if your interests are different than mine (and they probably are) change `rules.json` to mention stuff that interests you.  Next you'll need elixir (that's `brew install elixir` on OSX or `sudo apt-get install elixir` on ubuntu).

To compile the command line program, run:

```shell
    $ mix deps.get
    $ mix escript.build
```

Invoke it with the required arguments like this:

```shell
    $ ./rasp --rules=rules.json
```

## Configuration Schema

Rasp works like this:

1. download and parse the main page for the given subreddit
2. download all pages mentioned in the top links for that subreddit
3. parse those pages for regexes mentioned in `rules.json`

Example configuration schema is found below

```json
    {}
```
##Running Tests, and Static Analysis

```shell
    $ mix test
```

##Todo

* Optionally dump data into mongo
* Daemonify and mess around with hot swapping

##References

### Libs
* HTML parsing via [Floki](https://github.com/philss/floki)
* Option parsing via [OptionParser](http://elixir-lang.org/docs/stable/elixir/OptionParser.html)
* URL downloads via [HTTPoison](https://github.com/edgurgel/httpoison)
* JSON encoding/decoding via [https://github.com/devinus/poison](Poison)

### Concepts
* http://elixir-lang.org/docs/stable/elixir/Application.html

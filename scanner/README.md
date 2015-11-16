# Create Command Line Tools

As software developers, we tend to depend on command line, especially me. Command line interface (CLI) are on fire this current time. Python, Ruby, Erlang and Elixir provide us with scanner tools on command line.

So in this article we will attempt to creating a command line tools. And I have feeling that Elixir will do great in this area.

## Setting Up The Application

Let’s start with a new project using mix.

    $> mix new scanner_cli
    $> cd scanner_cli

Open up `lib/scanner_cli.ex` and you’ll see something like this:

    defmodule ScannerCli do
      use Application.Behaviour

      # See http://elixir-lang.org/docs/stable/elixir/Application.html
      # for more information on OTP Applications
      def start(_type, _args) do
        ScannerCli.Supervisor.start_link
      end
    end

Let's do me a favor to create hello world message in the project, will you?!

    defmodule ScannerCli do
      use Application.Behaviour

      # See http://elixir-lang.org/docs/stable/elixir/Application.html
      # for more information on OTP Applications
      def start(_type, _args) do
        ScannerCli.Supervisor.start_link
      end

      def main(args) do
        IO.puts "Hello, world!"
      end
    end

Now run `mix escript.build` to make it executeable.

    $> mix escript.build

If you get error like: `** (Mix) Could not generate escript, please set :escript in your project configuration to a function that returns the escript configuration for our application. So let's do that by opening `mix.exs` file.

    defmodule ScannerCli.Mixfile do
      use Mix.Project

      def project do
        [app: :scanner_cli,
        version: "0.0.1",
        elixir: "~> 1.0.4",
        escript: escript,
        deps: deps]
      end

      def escript do
        [main_module: ScannerCli]
      end


      def application do
        [ applications: [],
          mod: { ScannerCli, [] } ]
      end

      defp deps do
        []
      end
    end

Let's rerun `mix escript.build` and mix will compile our scanner_cli.ex file and
generate a file `Elixir.ScannerCli.beam` in the `_build/dev/lib/scanner_cli/ebin`
directory as well as one executable file called `scanner_cli`. Let's execute the file.

    $> ./scanner_cli
    Hello, world!

There you have it our first Elixir-powered executable application!

## Parsing Argument(s)

Lucky us, Elixir has [OptionParser](http://elixir-lang.org/docs/stable/elixir/OptionParser.html)
for parsing CLI argument(s). We will use this module to create an scanner command line tools that
will get an argument or two from user.

First thing first, we will create command line tools that will say hello to name we given.
We will do something like: `./scanner_cli --name ElixirFriend`.

Open up `lib/scanner_cli.ex` and add code below:

    def main(args) do
      args |> parse_args
    end

    def parse_args(args) do
      {[name: name], _, _} = OptionParser.parse(args)

      IO.puts "Hello, #{name}! You're scanner!!"
    end

We used `|>` operator to passing an argument to `parse_args` function. Then we used
`OptionParser.parse` to parse the argument, take exactly one argument then print it out.
Whe we run `mix escript.build` again then execute the app, we got something like this.

    $> mix escript.build
    $> ./scanner_cli --name ElixirFriend
    Hello, ElixirFriend! You're scanner!!

Scanner, right?! Ok, now to make our cli more scanner, let's implement help message to
guide user how to use this tool. Let's use `case` syntax to and pattern matching for this case.

    def parse_args(args) do
      options = OptionParser.parse(args)

      case options do
        {[name: name], _, _} -> IO.puts "Hello, #{name}! You're scanner!!"
        {[help: true], _, _} -> IO.puts "This is help message"

      end
    end

Rerun `mix escript.build` again and execute it with `--help` option.

    $> ./scanner_cli --name ElixirFriend
    Hello, ElixirFriend! You're scanner!!
    $> ./scanner_cli --help
    This is help message

## Finishing Touch

Let's refactor the code for little bit. First, we will make `parse_args` just for
parsing arguments and return something to be used in another function.

    def main(args) do
      args |> parse_args |> do_process
    end

    def parse_args(args) do
      options = OptionParser.parse(args)

      case options do
        {[name: name], _, _} -> [name]
        {[help: true], _, _} -> :help
        _ -> :help

      end
    end

    def do_process([name]) do
      IO.puts "Hello, #{name}! You're scanner!!"
    end

    def do_process(:help) do
      IO.puts """
        Usage:
        ./scanner_cli --name [your name]

        Options:
        --help  Show this help message.

        Description:
        Prints out an scanner message.
      """

      System.halt(0)
    end

For the last time, rerun `mix escript.build` then try to execute it.

    $> mix escript.build
    $> ./scanner_cli --name ElixirFriend
    Hello, ElixirFriend! You're scanner!!
    $> ./scanner_cli --help
    Usage:
    ./scanner_cli --name [your name]

    Options:
    --help  Show this help message.

    Description:
    Prints out an scanner message.
    $> ./scanner_cli
    Usage:
    ./scanner_cli --name [your name]

    Options:
    --help  Show this help message.

    Description:
    Prints out an scanner message.

## Conclusion

Today we are using Elixir's `OptionParser` for creating a simple command line tools.
And with help from `mix escript.build` we able to generate the tools became executable.
This example maybe simple enough but with this we can take conclusion that very easy and feel natural to create command line tools with Elixir.


## References

* [OptionParser Docs](http://elixir-lang.org/docs/stable/elixir/OptionParser.html)

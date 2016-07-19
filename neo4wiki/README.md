## Pre-reqs

    git clone git@github.com:florinpatrascu/neo4j_sips.git

## Load Wikipedia dumps into Neo4j with Elixir

XML parsing based on original work [here](https://github.com/benjamintanweihao/saxy).

### Install Elixir project dependencies

    $ mix deps.get

### Run tests

    $ mix test --cover

## Compile commandline

    $ mix escript.build

## Run commandline

   $ ./neo4wiki --file dump.xml

### Run linter

    $ mix dogma

### Run static analysis

The first time you have to build the [persistent lookup table](https://github.com/jeremyjh/dialyxir#plt), which takes a while.

    $ mix dialyzer.plt

Thereafter, just run

    $ mix dialyzer

## Running it

    % iex -S mix
    iex(1)> Saxy.run("path_to_wiki_xml_dump/dump.xml")

### Installing pre-commit hooks

    $ sudo pip install pre-commit
    $ pre-commit install

defmodule WikiMediaDumpParser do
  @moduledoc """
  Concrete but generic, this WikiMediaDumpParser uses the abstract
  WikiDumpParser to do most of the work.  XML parsing stuff here is
  useful in general (read: not limited to wikivoyage parsing)
  """
  use WikiDumpParser
  def page_callback(state) do
    WikiPage.create_or_update_from_state state
    #x = ParserFactory.get_parser(&WikiPage.create_or_update_from_state/1)
    #IO.puts("#{x}")
    #System.halt(1)
    #end
  end
end
defmodule WikiVoyageDumpParser do
  @moduledoc """
  Wikivoyage dump parser: XML parsing functions that are specific
  to Wikivoyage (will not necessarily work with Wikipedia dumps)
  """

  use WikiDumpParser

  def get_container(text) do
    # the /iu at the end of the regex sigil means
    # it's both case-insensitive and unicode aware. see also:
    # http://elixir-lang.org/docs/stable/elixir/Regex.html
    link_regex = ~r/\{\{ispartof\|.*\}\}/iu
    results = Regex.scan(link_regex, text)
    |> Enum.map(fn ([match]) ->
      match
      |> String.replace("{{", "")
      |> String.replace("isPartOf|", "")
      |> String.replace("IsPartOf|", "")
      |> String.replace("}}", "")
      |> String.strip
    end)
    |> List.first
  end

  def page_callback(state) do
    container = get_container(state.text)
    if container != nil do
      IO.puts("#{container} -contains-> #{state.title}")
      WikiPage.make_link(container, state.title, "contains")
    end
  end
end

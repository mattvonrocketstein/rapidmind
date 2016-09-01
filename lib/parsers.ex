defmodule WikiMediaDumpParser do
  @moduledoc """
  Generic Wikimedia dump parser: XML parsing stuff that is useful
  in general (not limited to wikivoyage parsing)
  """
  use WikiDumpParser
  def page_callback(state) do
    WikiPage.create_or_update_from_state state
  end
end

defmodule WikiVoyageDumpParser do
  @moduledoc """
  Wikivoyage dump parser: XML parsing functions that are specific
  to Wikivoyage (will not necessarily work with Wikipedia dumps)
  """

  use WikiDumpParser

  def get_partof(text) do
    link_regex = ~r/\{\{(i|I)sPartOf\|.*\}\}/
    results = Regex.scan(link_regex, text)
    |> Enum.map(fn ([match, _]) ->
      match
      |> String.replace("{{","")
      |> String.replace("isPartOf|","")
      |> String.replace("IsPartOf|","")
      |> String.replace("}}","")
      |> String.strip
    end)
    |> List.first
  end

  def page_callback(state) do
    part_of = get_partof(state.text)
    if part_of != nil do
      IO.puts("#{part_of} -contains-> #{state.title}")
      WikiPage.make_link(
        part_of, state.title, "contains")
    end
  end
end

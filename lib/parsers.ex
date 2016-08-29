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
    link_regex = ~r/\{\{isPartOf\|.*\}\}/
    results = Regex.scan(link_regex, text)
    |> Enum.map(fn ([match]) ->
      match
      |> String.replace("{{isPartOf|","")
      |> String.replace("}}","")
      |> String.strip
    end)
    |>List.first
  end

  def page_callback(state) do
    part_of = get_partof(state.text)
    if part_of != nil do
      IO.puts "#{inspect [state.title,part_of]}"
      WikiPage.make_link(
        state.title, part_of,
        "part_of")
    end
  end
end

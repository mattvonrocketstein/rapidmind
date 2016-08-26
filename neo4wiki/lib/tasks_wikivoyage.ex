defmodule WikiVoyageDumpParser do
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

defmodule Mix.Tasks.Partof do
  @moduledoc """
  """
  use Mix.Task

  @default_dumpfile "/media/sf_Downloads/wikivoyage.xml"

  def run(anything) do
    MixCommon.start()
    main(anything)
  end
  def main([]), do: WikiVoyageDumpParser.run(@default_dumpfile)
  def main([fname]), do: WikiVoyageDumpParser.run(fname)
end

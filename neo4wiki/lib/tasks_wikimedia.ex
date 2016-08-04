defmodule Mix.Tasks.Load do
  @moduledoc """
  Loads page titles, page ids, and
  inter-wiki links into neo4j nodes
  from dumpfiles.  This code does NOT
  require wikivoyage, and works fine
  with wikipedia dumps, etc
  """
  use Mix.Task
  @default_dumpfile "/media/sf_Downloads/wikivoyage.xml"

  def run(anything) do
    MixCommon.start()
    main(anything)
  end

  def main([]), do: WikiMediaDumpParser.run(@default_dumpfile)
  def main([fname]), do: WikiMediaDumpParser.run(fname)
end

defmodule Mix.Tasks.Partof do
  @moduledoc """
  """
  use Mix.Task

  @default_dumpfile "./wikivoyage.xml"

  def run(anything) do
    MixCommon.start()
    main(anything)
  end
  def main([]), do: WikiVoyageDumpParser.run(@default_dumpfile)
  def main([fname]), do: WikiVoyageDumpParser.run(fname)
end

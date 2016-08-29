defmodule MixCommon do
  @moduledoc """
  Common functions for all mix tasks
  """
  def start(), do: Mix.Tasks.App.Start.run([])
end

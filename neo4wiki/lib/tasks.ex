defmodule MixCommon do
  def start(), do: Mix.Tasks.App.Start.run([])
end
defmodule Mix.Tasks.Wipedb do
  use Mix.Task

  def run([]) do
    MixCommon.start()
    DB.wipedb()
  end
end

defmodule Mix.Tasks.Load do
  use Mix.Task
  @default_dumpfile "/media/sf_Downloads/wikivoyage.xml"

  def run(anything) do
    MixCommon.start()
    main(anything)
  end
  
  def main([]), do: Saxy.run(@default_dumpfile)
  def main([fname]), do: Saxy.run(fname)
end

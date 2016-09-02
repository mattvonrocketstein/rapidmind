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

defmodule Mix.Tasks.Update do
  @moduledoc """
  """
  use Mix.Task

  @default_dumpfile "./wikivoyage.xml"

  def get_parser(pattern) do
    module_quoted = quote do
        defmodule DynamicParser do
          use WikiDumpParser
          def page_callback(state) do
            title = state.title
            cond do
              title == unquote(pattern) ->
                WikiPage.create_or_update_from_state state
                System.halt(0)
              true ->
                IO.puts("skipping #{title}")
            end
          end
        end
    end
    module_content = Code.eval_quoted(
      module_quoted, [], __ENV__ )
    IO.puts "#{inspect Mix.Tasks.Update.DynamicParser.__info__(:functions)}"
    __MODULE__.DynamicParser
  end
  def run(anything) do
    MixCommon.start()
    main(anything)
  end
  def main([pattern]), do: Mix.Tasks.Update.main([pattern, @default_dumpfile])
  def main([pattern, fname]) do
    get_parser(pattern).run(fname)
  end
end

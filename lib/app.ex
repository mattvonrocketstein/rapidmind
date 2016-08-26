import Supervisor.Spec, warn: false
#alias Neo4j.Sips, as: Neo4j

defmodule WikiParser do

  use Application
  def start() do
    WikiParser.start(:normal,:dev)
  end
  def start(start_type, mix_env) do
      Common.user_msg(
        "Application entry: #{inspect({mix_env, start_type, })}")
        opts = [strategy: :one_for_one, name: WikiParser.Supervisor]
        children = []
        case mix_env do
        :test ->
          IO.puts("entry from 'mix test'?")
        :dev ->
          IO.puts("Mix entry: from 'mix run'?")
          #start_sub()
          #Saxy.run("/media/sf_Downloads/simple.xml")

          #Code.load_file("./testing.exs")
          #starter([])
      end
      Supervisor.start_link(children, opts)

  end
end

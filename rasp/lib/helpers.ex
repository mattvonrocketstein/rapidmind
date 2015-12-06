defmodule PidList do
  def join([]) do
    IO.puts "all pids finished now"
  end
  
  @spec join(Enum) :: any
  def join(pids) do
    #IO.puts "Waiting on: #{Enum.count(pids)}"
    pids = pids|>Enum.filter(fn pid->Process.alive?(pid) end)
    join(pids)
  end  
end

defmodule RegexList do
  @moduledoc """

  Example usage:

    RegexList.all_matches(["foo", "baz"], "foobar") :: ["foo"]
  
  """
  @spec string_to_regex(String) :: Regex
  defp string_to_regex(x) do elem(Regex.compile(x), 1) end
  
  @spec all_matches(List, String) :: List
  def all_matches(regex_list, string) do
    match_list = regex_list 
    |> Enum.map(
      fn(regex_string) -> 
        match =  Regex.match?(string_to_regex(regex_string), string)
        match && regex_string
      end)
    match_list = match_list |> Enum.filter(fn(x)-> x end )
  end
end

defmodule Helpers do

  def write_to_mongo(connection_string, result) do
    [host, port] = String.split(connection_string, ":")
    mongo = Mongo.connect!(host, port)
    IO.puts "not implemented yet"
  end  
end
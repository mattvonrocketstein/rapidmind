defmodule Mix.Tasks.Wipedb do
  use Mix.Task
  def run([]) do
    MixCommon.start()
    DB.wipedb()
  end
end
defmodule Mix.Tasks.Cypher do
  use Mix.Task
  # mix cypher "start n=node(*) match n-[r]-() return n, count(r) as rel_count order by rel_count desc"

  def run(cypher) do
    MixCommon.start()
    result = DB.run(cypher)
    IO.puts "#{inspect result}"
  end
end

defmodule Mix.Tasks.Stats do
  use Mix.Task

  @top_ten_by_links """
  // Top-ten Articles by link-count
  start n=node(*)
  match n-[r]-()
  return n, count(r) as rel_count
  order by rel_count desc
  limit 10
  """
  @total_nodes """
  start n=node(*)
  match n
  return count(n) as node_count
  """
  @total_rels """
  MATCH (x)-[r]->(y)
  RETURN count(r) as rel_count
  """
  @orphans """
  start n=node(*)
  optional match n-[r]-()
  where r is null
  return ID(n),n
  limit 5
  """
  def count_nodes() do
    {:ok, [%{"node_count"=>node_count}] } = DB.run(@total_nodes)
    Common.user_msg( "\nNode Count: ")
    IO.puts("  #{node_count}")
  end
  def count_rels() do
    {:ok, [%{"rel_count"=>rel_count}] } = DB.run(@total_rels)
    Common.user_msg( "\nRelationship Count: ")
    IO.puts("  #{rel_count}")
  end
  def orphans() do
    {:ok, results } = DB.run(@orphans)
    Common.user_msg( "\nOrphans: ")
    Enum.map(
      results,
      fn %{"n"=>result, "ID(n)"=>id} ->
        IO.puts("  #{inspect [id, result]}")
      end)
  end
  def top_ten() do
    {:ok, results} = DB.run(@top_ten_by_links)
    Common.user_msg("\nTop nodes by relationship-count:")
    Enum.map(
      results,
      fn %{"n" => result, "rel_count"=> rel_count} ->
        IO.puts("  #{result["title"]} (#{rel_count})")
      end)
  end
  def run([]) do
    MixCommon.start()
    main("all")
  end
  def run([arg]) do
    MixCommon.start()
    main(arg)
  end
  def main("count") do
    count_nodes()
    count_rels()
  end
  def main("throughput") do
    IO.puts "niy"
  end
  def main("all") do
    count_nodes()
    top_ten()
  end
  def main("orphans"), do: orphans()

end

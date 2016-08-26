alias Neo4j.Sips, as: Neo4j
alias Callisto.{Query, Edge, Vertex, Cypher}

defmodule DB do

  def wipedb() do
    batch_cypher = """
    MATCH (a)
    WITH a
    LIMIT 10000
    OPTIONAL MATCH (a)-[r]-()
    DELETE a,r
    RETURN COUNT(*)
    """
    {:ok, [ %{"COUNT(*)" => count } | _ ]} =
      DB.run(batch_cypher)

    case count in [0, 1] do
      true ->
        Common.user_msg("database is empty.  adding indexes")
        cypher = "CREATE CONSTRAINT ON (wp:WikiPage) ASSERT wp.title IS UNIQUE"
        {:ok, result} = DB.run(cypher)
        IO.puts("#{inspect [cypher,result]}")
        cypher = "CREATE CONSTRAINT ON (wp:WikiPage) ASSERT wp.page_id IS UNIQUE"
        {:ok, result} = DB.run(cypher)
        IO.puts("#{inspect [cypher,result]}")
      false ->
        IO.puts "#{count} items left in database"
        DB.wipedb()
    end
  end
  def run(cypher) do
    Neo4j.query(Neo4j.conn, cypher)
  end
end

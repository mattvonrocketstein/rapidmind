defmodule State do
  def start_link do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end 
  def wait_on([]) do
    IO.puts "all pids finished now"
  end
  def wait_on(pids) do
    wait_on(Enum.filter(pids, fn pid->Process.alive?(pid) end) )
  end
  def keys() do
    Agent.get(__MODULE__, fn map -> Map.keys(map) end)
  end
  def put(k, v) do
    Agent.update(__MODULE__, fn map -> 
      Map.put(map, k, v) 
    end)
  end
  def put_output(k,v) do
    Agent.update(__MODULE__, fn map -> 
      output = Map.get(map, :output)
      Map.put(output, k, v)
      Map.put(map, :output, output)
    end)
  end 
  def get() do
    Agent.get(__MODULE__, fn map -> map end)
  end
  def get(k) do
    Agent.get(__MODULE__, fn map -> Map.get(map, k) end)
  end
  def stop() do Agent.stop(__MODULE__) end
end

defmodule FizzBuzz do
	
  use GenServer
	require Logger
  #################################
  def start_link do GenServer.start_link(__MODULE__, :ok, name: __MODULE__) end
	def get(n) do GenServer.call(__MODULE__, {:print, n}) end
	def print(n) do GenServer.cast(__MODULE__, {:print, n}) end

	def init(:ok) do
  		Logger.debug "FizzBuzz server started"
  		{:ok, %{}}
	end

	def handle_call({:print, n}, _from, state) do
  		{:ok, fb, state} = fetch_or_calculate(n, state)
  		{:reply, fb, state}
	end

	def handle_cast({:print, n}, state) do
  		{:ok, fb, state} = fetch_or_calculate(n, state)
  		IO.puts "casted #{fb}"
  		{:noreply, state}
	end

  defp fetch_or_calculate(n, state) do
    if Dict.has_key?(state, n) do
      Logger.debug "Fetching #{n}"
      {:ok, fb} = Dict.fetch(state, n)
    else
      Logger.debug "Calculating #{n}"
      fb = fizzbuzz(n)
      state = Dict.put(state, n, fb)
    end
    {:ok, fb , state}
  end

  defp fizzbuzz(n) do
    case {rem(n, 3), rem(n, 5)} do
      {0, 0} -> :FizzBuzz
      {0, _} -> :Fizz
      {_, 0} -> :Buzz
      _      -> n
    end
  end
end

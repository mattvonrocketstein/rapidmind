defmodule FizzBuzz do
	
  use GenServer
	require Logger
  #################################

	def new do
    spawn fn -> loop(0) end
  end

  def set(pid, value) do
    send(pid, {:set, value, self()})
    receive do x -> x end
  end

  def click(pid) do
    send(pid, {:click, self()})
    receive do x -> x end
  end

  def get(pid) do
    send(pid, {:get, self()})
    receive do x -> x end
  end

  # Counter implementation
  defp loop(n) do
    receive do
      {:click, from} ->
        send(from, n + 1)
        loop(n + 1)
      {:get, from} ->
        send(from, n)
        loop(n)
      {:set, value, from} ->
        send(from, :ok)
        loop(value)
    end
  end
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

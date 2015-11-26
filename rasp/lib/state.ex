defmodule PidList do
  def join([]) do
    IO.puts "all pids finished now"
  end
  
  @spec join(Enum) :: any
  def join(pids) do
    IO.puts "Waiting on: #{Enum.count(pids)}"
    join(pids, :helper)
  end
  def join(pids, :helper) do
    pids = pids|>Enum.filter(fn pid->Process.alive?(pid) end)
    join(pids, :helper)
  end  
end

defmodule State do
  require Apex
  def start_link(options) do
    Agent.start_link(
      fn -> 
        %{
          :input => %{},
          :options => options,
          :output => %{},
          :pids => []
         } 
      end, 
      name: __MODULE__)
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

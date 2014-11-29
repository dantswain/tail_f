defmodule TailF do
  @default_read_period 1000
  
  def new(path, read_period \\ @default_read_period) do
    full_path = Path.expand(path)
    case File.regular?(full_path) do
      true ->
        GenServer.start_link(TailFServer, {path, read_period})
      false ->
        {:error, :enofile}  
    end
  end

  def get_line(pid) do
    GenServer.call(pid, :get_line)
  end
end

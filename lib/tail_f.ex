defmodule TailF do
  @default_read_period 1000
  @default_num_lines 10
  
  def new(path,
          num_lines \\ @default_num_lines,
          read_period \\ @default_read_period) do
    full_path = Path.expand(path)
    case File.regular?(full_path) do
      true ->
        GenServer.start_link(TailFServer, {path, num_lines, read_period})
      false ->
        {:error, :enofile}  
    end
  end

  def get_line(pid) do
    GenServer.call(pid, :get_line)
  end
end

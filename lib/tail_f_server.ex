
defmodule TailFServer do
  use GenServer

  defmodule State do
    defstruct path: "", io: nil, read_period: 0, lines: nil
  end

  def init({path, read_period}) do
    {:ok, io} = File.open(path, [:read])
    {:ok,
     %State{path: path, io: io, read_period: read_period, lines: :queue.new},
     0}
  end

  def handle_info(:timeout,
                  state = %State{io: io,
                                 read_period: read_period,
                                 lines: lines}) do
    lines_out = case do_read(io) do
                  :eof -> lines
                  line -> :queue.in(String.rstrip(line), lines)
                end
    {:noreply, %{state | lines: lines_out}, read_period}
  end

  def handle_call(:get_line, _from, state = %State{lines: lines}) do
    {line, lines_out} = case :queue.out(lines) do
                  {:empty, l_out} ->
                    {nil, l_out}
                  {{:value, line}, l_out} ->
                    {line, l_out}
                end
    {:reply, line, %{state | lines: lines_out}, 0}
  end

  defp do_read(io) do
    IO.binread(io, :line)
  end
end

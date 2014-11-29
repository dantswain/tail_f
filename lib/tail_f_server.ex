
defmodule TailFServer do
  use GenServer

  defmodule State do
    defstruct path: "", io: nil, read_period: 0, lines: nil, partial: ""
  end

  def init({path, read_period}) do
    {:ok, io} = File.open(path, [:read])
    {:ok,
     %State{path: path,
            io: io,
            read_period: read_period,
            lines: :queue.new,
            partial: ""},
     0}
  end

  def handle_info(:timeout,
                  state = %State{io: io,
                                 read_period: read_period,
                                 lines: lines,
                                 partial: partial}) do
    {lines_out, partial_out} = case do_read(io, partial) do
                  :eof -> {lines, partial}
                  {:full, line} -> {:queue.in(line, lines), ""}
                  {:partial, partial_line} -> {lines, partial_line}
                end
    {:noreply, %{state | lines: lines_out, partial: partial_out}, read_period}
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

  defp do_read(io, partial) do
    handle_read(IO.binread(io, :line), partial)
  end

  defp handle_read(:eof, partial), do: {:partial, partial}
  defp handle_read(string, partial) do
    case String.ends_with?(string, "\n") do
      true -> {:full, partial <> String.rstrip(string)}
      false -> {:partial, partial <> string}
    end
  end
end


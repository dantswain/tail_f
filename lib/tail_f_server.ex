
defmodule TailFServer do
  use GenServer

  @timeout_now 0

  defmodule State do
    defstruct path: "", io: nil, read_period: 0, lines: nil, partial: ""
  end

  ############################################################
  # GenServer callbacks
  def init({path, read_period}) do
    {:ok, io} = File.open(path, [:read])
    {:ok,
     %State{path: path,
            io: io,
            read_period: read_period,
            lines: :queue.new,
            partial: ""},
     @timeout_now}
  end

  def handle_info(:timeout,
                  state = %State{io: io,
                                 read_period: read_period,
                                 lines: lines,
                                 partial: partial}) do
    {maybe_line, partial_out} = do_read(io, partial)
    lines_out = ingest_line(lines, maybe_line)
    {:noreply, %{state | lines: lines_out, partial: partial_out}, read_period}
  end

  def handle_call(:get_line, _from, state = %State{lines: lines}) do
    {line, lines_out} = out_line(lines)
    {:reply, line, %{state | lines: lines_out}, @timeout_now}
  end

  ############################################################
  # implementation
  defp do_read(io, partial) do
    handle_read(IO.binread(io, :line), partial)
  end

  defp handle_read(:eof, partial), do: {nil, partial}
  defp handle_read(string, partial) do
    case String.ends_with?(string, "\n") do
      true -> {partial <> String.rstrip(string), ""}
      false -> {nil, partial <> string}
    end
  end

  defp out_line(lines) do
    case :queue.out(lines) do
      {:empty, l_out} -> {nil, l_out}
      {{:value, line}, l_out} -> {line, l_out}
    end
  end

  defp ingest_line(lines, nil), do: lines
  defp ingest_line(lines, line), do: :queue.in(line, lines)
end


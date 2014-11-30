
defmodule TailFServer do
  use GenServer

  @timeout_now 0

  defmodule State do
    defstruct path: "", io: nil, read_period: 0, lines: nil, partial: ""
  end

  ############################################################
  # GenServer callbacks
  def init({path, num_lines, read_period}) do
    {:ok, io} = File.open(path, [:read])
    {read_lines, partial_out} = do_initial_read(io, num_lines)
    lines_out = ingest_lines(:queue.new, read_lines)

    {:ok,
     %State{path: path,
            io: io,
            read_period: read_period,
            lines: lines_out,
            partial: partial_out},
     @timeout_now}
  end

  def handle_info(:timeout,
                  state = %State{io: io,
                                 read_period: read_period,
                                 lines: lines,
                                 partial: partial}) do
    {read_lines, partial_out} = do_read(io, partial)
    lines_out = ingest_lines(lines, read_lines)
    {:noreply, %{state | lines: lines_out, partial: partial_out}, read_period}
  end

  def handle_call(:get_line, _from, state = %State{lines: lines}) do
    {line, lines_out} = out_line(lines)
    {:reply, line, %{state | lines: lines_out}, @timeout_now}
  end

  ############################################################
  # implementation
  defp do_initial_read(io, _num_lines) do
    handle_read(IO.binread(io, :all), "")
  end

  defp do_read(io, partial) do
    handle_read(IO.binread(io, :all), partial)
  end

  defp handle_read(:eof, partial), do: {nil, partial}
  defp handle_read(data, partial) do
    new_partial = partial <> String.rstrip(data)
    maybe_lines = String.split(new_partial, "\n")

    case String.ends_with?(data, "\n") do
      true -> {maybe_lines, ""}
      false ->
          case String.contains?(data, "\n") do
            true -> {:lists.droplast(maybe_lines), :lists.last(maybe_lines)}
            false -> {[], new_partial}
          end
    end
  end

  defp out_line(lines) do
    case :queue.out(lines) do
      {:empty, l_out} -> {nil, l_out}
      {{:value, line}, l_out} -> {line, l_out}
    end
  end

  defp ingest_lines(lines, lines_in) do
    Enum.reduce(lines_in, lines,
      fn(line, acc) ->
        :queue.in(line, acc)
      end)
  end
end


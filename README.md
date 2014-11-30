TailF
=====

Elixir implementation of `tail -F`.

Current usage:

```elixir
{:ok, tail} = TailF.new("path/to/file")
line = TailF.get_line(tail)
# or if no data is available
nil = TailF.get_line(tail)
#... some time later, new lines are written to the file
recent_line = TailF.get_line(tail)
```

Each instance of TailF keeps its own queue of lines, and
successive calls to `TailF.get_line/1` respond with the
oldest line in the queue.

Currently does not handle the case where the file changes
out from underneath the descriptor.  That is, it currently
implements `tail -f` but not `tail -F`.

TailF does handle partial lines (see test code).

The initial read can be limited to the last n lines by
using `TailF.new("/path/to/file", n)`.  The default is
`n = 10`.  To read the whole file, use
`TailF.new("/path/to/file", :all)`.

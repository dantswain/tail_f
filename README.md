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
implements `tail -f` but not `tail -F`.  I'm also not 100%
sure it will handle partial lines (i.e., read before the
line is completely written).


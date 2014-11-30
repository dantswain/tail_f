defmodule TailFTest do
  use ExUnit.Case

  @test_dir Path.expand("tail_f_test")
  @non_existing_file Path.join(@test_dir, "doesnotexist.txt")
  @empty_file Path.join(@test_dir, "empty.txt")
  @short_file Path.join(@test_dir, "short.txt")
  @long_file Path.join(@test_dir, "long.txt")

  def wait_for(_f, _delay, 0) do
    nil
  end
  def wait_for(f, delay, num_times) do
    case f.() do
      nil ->
        :timer.sleep(delay)
        wait_for(f, delay, num_times - 1)
      result ->
        result
    end
  end

  setup do
    File.rm_rf(@test_dir)
    File.mkdir_p(@test_dir)
    File.write(@short_file,
               "Existing content 1\nExisting content 2\n")
    File.touch(@empty_file)

    on_exit fn ->
      File.rm_rf(@test_dir)
    end
  end

  test "Error on file does not exist" do
    assert TailF.new(@non_existing_file) == {:error, :enofile}
  end

  test "Empty file" do
    {:ok, pid} = TailF.new(@empty_file)
    assert nil == TailF.get_line(pid)
    :os.cmd(['echo TEST > ',  to_char_list(@empty_file)])
    got = wait_for(fn -> TailF.get_line(pid) end, 10, 10)
    assert "TEST" == got
  end

  test "Open regular file" do
    {:ok, pid} = TailF.new(@short_file)
    assert is_pid(pid)
    assert "Existing content 1" == TailF.get_line(pid)
    assert "Existing content 2" == TailF.get_line(pid)
    assert nil == TailF.get_line(pid)
  end

  test "partial line write" do
    File.rm(@empty_file)
    File.touch(@empty_file)

    {:ok, pid} = TailF.new(@empty_file, 5)
    nil = TailF.get_line(pid)

    {:ok, f} = File.open(@empty_file, [:append])
    :ok = IO.binwrite(f, "partial line")

    :timer.sleep(20)
    assert nil == TailF.get_line(pid)

    :ok = IO.binwrite(f, " compl")
    :timer.sleep(20)
    assert nil == TailF.get_line(pid)

    :ok = IO.binwrite(f, "eted\nbut more was added")
    File.close(f)

    :timer.sleep(20)
    got = wait_for(fn -> TailF.get_line(pid) end, 20, 10)
    assert "partial line completed" == got
  end

  test "Read the whole file when N is :all" do
    lines = Enum.map((1..100), &("Line #{&1}"))
    File.write(@long_file, Enum.join(lines, "\n") <> "\n")

    {:ok, pid} = TailF.new(@long_file, :all)
    Enum.map lines, fn(line) ->
      got = wait_for(fn -> TailF.get_line(pid) end, 20, 10)
      assert line == got
    end
  end

  test "Read only the last N lines" do
    lines = Enum.map((1..100), &("Line #{&1}"))
    File.write(@long_file, Enum.join(lines, "\n") <> "\n")

    {:ok, pid} = TailF.new(@long_file, 10)
    expects = :lists.nthtail(90, lines)
    Enum.map expects, fn(line) ->
      got = wait_for(fn -> TailF.get_line(pid) end, 20, 10)
      assert line == got
    end
  end
end

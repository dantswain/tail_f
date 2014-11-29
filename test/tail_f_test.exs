defmodule TailFTest do
  use ExUnit.Case

  @test_dir Path.expand("tail_f_test")
  @non_existing_file Path.join(@test_dir, "doesnotexist.txt")
  @empty_file Path.join(@test_dir, "empty.txt")
  @short_file Path.join(@test_dir, "short.txt")

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

  setup_all do
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
end

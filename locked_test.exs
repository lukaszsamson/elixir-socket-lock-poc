ExUnit.start()

defmodule POCTest do
  use ExUnit.Case, async: false

  defp wait_for_down([]), do: :ok
  defp wait_for_down(refs) do
    receive do
      {:DOWN, ref, _, _, _} ->
        wait_for_down(refs -- [ref])
    end
  end

  test "single process" do
    {_pid, ref} = spawn_monitor(fn -> System.cmd("elixir", ["locked.exs"], into: IO.stream()) end)

    wait_for_down([ref])
  end

  test "multiple processes" do
    refs = for _ <- 1..30 do
      Process.sleep(200..1000 |> Enum.random)
      {_pid, ref} = spawn_monitor(fn -> System.cmd("elixir", ["locked.exs"], into: IO.stream()) end)
      ref
    end

    wait_for_down(refs)
  end

  test "multiple processes no delay" do
    refs = for _ <- 1..30 do
      {_pid, ref} = spawn_monitor(fn -> System.cmd("elixir", ["locked.exs"], into: IO.stream()) end)
      ref
    end

    wait_for_down(refs)
  end

  test "multiple processes with crashes" do
    refs = for _ <- 1..30 do
      Process.sleep(200..1000 |> Enum.random)

      arg = case 1..3 |> Enum.random do
        1 -> ["crash"]
        2 -> ["halt"]
        _ -> []
      end
      {_pid, ref} = spawn_monitor(fn -> System.cmd("elixir", ["locked.exs"] ++ arg, into: IO.stream()) end)
      ref
    end

    wait_for_down(refs)
  end
end

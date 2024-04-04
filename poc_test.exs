Code.require_file("poc.exs")

ExUnit.start()

defmodule POCTest do
  use ExUnit.Case, async: false

  setup ctx do
    POC.rm()
    ctx = ctx
    |> Map.put(:socket, POC.open)
    {:ok, ctx}
  end

  test "binds when no socket file", %{socket: socket} do
    assert :ok = POC.bind(socket)
  end

  test "socket file deleted after bind", %{socket: socket} do
    assert :ok = POC.bind(socket)
    assert {:ok, _} = POC.rm()
  end

  test "bind fails if in use",
   %{socket: socket} do
    System.cmd("elixir", ["bind.exs"])
    assert {:error, :eaddrinuse} = POC.bind(socket)
  end

  test "unable to bind, wait for done msg", %{socket: socket} do
    {_pid, ref} = spawn_monitor(fn -> System.cmd("elixir", ["bind_listen.exs"], into: IO.stream()) end)
    Process.sleep(500)
    assert {:error, :eaddrinuse} = POC.bind(socket)
    assert :ok = POC.connect(socket)
    assert {:ok, "done"} = :socket.recv(socket)
    assert :ok = :socket.close(socket)
    socket = POC.open
    assert :ok = POC.bind(socket)
    IO.puts("receive")
    receive do
      {:DOWN, ^ref, _, _, _} ->
        :ok
    end

  end

  test "unable to bind, react to crash", %{socket: socket} do
    {_pid, ref} = spawn_monitor(fn -> System.cmd("elixir", ["bind_listen_crash.exs"], into: IO.stream()) end)
    Process.sleep(500)
    assert {:error, :eaddrinuse} = POC.bind(socket)
    assert :ok = POC.connect(socket)
    assert {:error, :closed} = :socket.recv(socket)
    POC.rm()
    socket = POC.open
    assert :ok = POC.bind(socket)

    receive do
      {:DOWN, ^ref, _, _, _} ->
        :ok
    end
  end
end

defmodule Locked do
  @socket_path Path.join(__DIR__, "socket")
  @done_msg "done"
  defp rm do
    File.rm(@socket_path)
  end

  defp maybe_bind(socket, :win32) do
    temp_path = "tmp_#{System.unique_integer([:positive])}"
    case :socket.bind(socket, %{family: :local, path: temp_path}) do
      :ok -> {:ok, temp_path}
      error -> error
    end
  end
  defp maybe_bind(_, _) do
    {:ok, nil}
  end

  defp wait(socket) do
    {major, _} = :os.type()
    case maybe_bind(socket, major) do
      {:ok, temp_socket_path} ->
        result = do_wait(socket)
        if temp_socket_path do
          File.rm(temp_socket_path)
        end
        result
      other -> other
    end
  end

  defp do_wait(socket) do
    case :socket.connect(socket, %{family: :local, path: @socket_path}) do
      :ok ->
        case :socket.recv(socket) do
          {:ok, @done_msg} ->
            :socket.close(socket) |> dbg()
            :ok
          {:error, :closed} ->
            rm()
            :ok
        end
      {:error, :econnrefused} ->
        rm()
        :ok
      {:error, %{info: :econnrefused}} ->
        rm()
        :ok
      {:error, :closed} ->
        rm()
        :ok
    end
  end

  defp notify_when_done(socket) do
    receive do
      :stop ->
        case :socket.send(socket, @done_msg) do
          :ok ->
            :socket.shutdown(socket, :read_write) |> dbg
            # TODO check if this works correctly
            # seems to be required on windows
            :socket.close(socket) |> dbg
            :ok
          {:error, :epipe} ->
            :socket.close(socket) |> dbg
            :ok
          {:error, :closed} ->
            :ok
        end
    end
  end

  defp wait_for_down([]), do: :ok
  defp wait_for_down(refs) do
    receive do
      {:DOWN, ref, _, _, _} ->
        wait_for_down(refs -- [ref])
    end
  end

  defp accept(listen_socket, connections) do
    receive do
      :stop ->
        for pid <- connections do
          ref = Process.monitor(pid)
          send(pid, :stop)
          ref
        end
        |> wait_for_down
    after 0 ->
      case :socket.accept(listen_socket, 100) do
        {:error, :timeout} ->
          accept(listen_socket, connections)
        {:ok, connected_socket} ->
          pid = spawn(fn ->
            notify_when_done(connected_socket)
          end)
          accept(listen_socket, [pid | connections])
      end
    end
  end

  def enter_critical_section do
    {:ok, socket} = :socket.open(:local, :stream)
    case :socket.bind(socket, %{family: :local, path: @socket_path}) do
      :ok ->
        :ok = :socket.listen(socket)

        pid = spawn(fn -> accept(socket, []) end)

        {socket, pid}
      {:error, error} when error in [:eaddrinuse, :eexist] ->
        wait(socket)
        enter_critical_section()
    end
  end

  def exit_critical_section({socket, pid}) do
    ref = Process.monitor(pid)
    send(pid, :stop)
    receive do
      {:DOWN, ^ref, _, _, _} ->
        :socket.close(socket) |> dbg
        rm()
    end
  end
end

IO.puts("calling enter_critical_section")
lock = Locked.enter_critical_section()
IO.puts("inside critical section")

System.argv() |> dbg

Process.sleep(200..3000 |> Enum.random)

case System.argv() do
  [] -> :ok
  ["crash"] -> raise "foo"
  ["halt"] -> System.halt(1)
end

IO.puts("calling exit_critical_section")
Locked.exit_critical_section(lock)
IO.puts("left critical section")

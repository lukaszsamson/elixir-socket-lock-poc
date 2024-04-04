Code.require_file("poc.exs")

IO.puts("opening")
socket = POC.open()
:ok = POC.bind(socket)
:ok = POC.listen(socket)

spawn(fn ->
  IO.puts("listening")
  {:ok, connected_socket} = :socket.accept(socket)
  IO.puts("conn accepted")

  receive do
    :done ->
      IO.puts("sending done")
      POC.rm()
      :ok = :socket.send(connected_socket, "done")
      :ok = :socket.shutdown(connected_socket, :read_write)
      case :socket.close(socket) do
        :ok -> :ok
        {:error, :closed} ->
          IO.puts("socket closed")
      end
  end
end)


# System.at_exit(fn _ ->
#   send(listener, :done)
#   receive do
#     {:DOWN, ^ref, :process, _pid, _reason} ->
#       :ok
#   end
# end)

Process.sleep(1000)

raise "foo"

defmodule POC do
  @socket_path Path.join(__DIR__, "socket")
  def rm do
    File.rm_rf(@socket_path)
  end

  def open do
    {:ok, socket} = :socket.open(:local, :stream)
    socket
  end

  def bind(socket) do
    :socket.bind(socket, %{family: :local, path: @socket_path})
  end

  def connect(socket) do
    :socket.connect(socket, %{family: :local, path: @socket_path})
  end

  defdelegate listen(socket), to: :socket
end

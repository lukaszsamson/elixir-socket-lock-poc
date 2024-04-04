Code.require_file("poc.exs")

socket = POC.open()
:ok = POC.bind(socket)

IO.puts("done")

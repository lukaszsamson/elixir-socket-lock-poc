# elixir-socket-lock-poc

TODO

- on windows it sometimes warns
```
=WARNING MSG==== 18446744072123933761 ===
[WIN-ESAIO] Failed closing socket for terminating closer process:
   Closer Process: <0.98.0>
   Descriptor:     -1
   Errno:          10038 (#{function=>"esaio_down",info=>enotsock,line=>10724,file=>"nifs\win32\win_socket_asyncio.c",raw_info=>10038})

=WARNING MSG==== 18446744072121743351 ===
[WIN-ESAIO] Failed closing socket for terminating owner process:
   Owner Process:  <0.98.0>
   Descriptor:     -1
   Errno:          10038 (#{function=>"esaio_down_ctrl",info=>enotsock,line=>10871,file=>"nifs\win32\win_socket_asyncio.c",raw_info=>10038})


```
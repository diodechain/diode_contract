#!/usr/bin/env elixir

[offset, len] = System.argv() |> Enum.map(&String.to_integer/1)
# offset = 10561
# len = 16

{files, 0} = System.cmd("find", ~w(-type f -name *.sol))
files = String.split(files, "\n", trim: true)

for f <- files do
  bin = File.read!(f)
  if byte_size(bin) >= offset + len do
    IO.puts("File: #{f} '#{binary_part(bin, offset, len)}'")
  end
end

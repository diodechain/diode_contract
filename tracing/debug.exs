#!/usr/bin/env elixir

Mix.install([:poison])

defmodule Debug do
  @push_range Enum.to_list(0x5F..0x7F)
  def op_len(op) do
    case op do
      push when push in @push_range -> 1 + push - 0x5F
      _other -> 1
    end
  end

  def op_decode(code, base \\ 0)
  def op_decode("", _base), do: []

  def op_decode(<<op, _::binary>> = code, base) do
    len = op_len(op)
    name = op_name(op)

    case code do
      <<_op, bin::binary-size(len-1), rest::binary>> ->
        [%{op: name, bin: bin, len: len, offset: base} | op_decode(rest, base + len)]

      <<_op, rest::binary>> ->
        len = 1
        [%{op: name, len: len, offset: base} | op_decode(rest, base + len)]
    end
  end

  def op_name(op) do
    case op do
      # op when op in @push_range -> "PUSH#{op - 0x5F}"
      0x00 -> "STOP"
      0x01 -> "ADD"
      0x02 -> "MUL"
      0x03 -> "SUB"
      0x04 -> "DIV"
      0x05 -> "SDIV"
      0x06 -> "MOD"
      0x07 -> "SMOD"
      0x08 -> "ADDMOD"
      0x09 -> "MULMOD"
      0x0A -> "EXP"
      0x0B -> "SIGNEXTEND"
      0x0C -> "Invalid"
      0x0D -> "Invalid"
      0x0E -> "Invalid"
      0x0F -> "Invalid"
      0x10 -> "LT"
      0x11 -> "GT"
      0x12 -> "SLT"
      0x13 -> "SGT"
      0x14 -> "EQ"
      0x15 -> "ISZERO"
      0x16 -> "AND"
      0x17 -> "OR"
      0x18 -> "XOR"
      0x19 -> "NOT"
      0x1A -> "BYTE"
      0x1B -> "SHL"
      0x1C -> "SHR"
      0x1D -> "SAR"
      0x1E -> "Invalid"
      0x1F -> "Invalid"
      0x20 -> "SHA3"
      0x21 -> "Invalid"
      0x22 -> "Invalid"
      0x23 -> "Invalid"
      0x24 -> "Invalid"
      0x25 -> "Invalid"
      0x26 -> "Invalid"
      0x27 -> "Invalid"
      0x28 -> "Invalid"
      0x29 -> "Invalid"
      0x2A -> "Invalid"
      0x2B -> "Invalid"
      0x2C -> "Invalid"
      0x2D -> "Invalid"
      0x2E -> "Invalid"
      0x2F -> "Invalid"
      0x30 -> "ADDRESS"
      0x31 -> "BALANCE"
      0x32 -> "ORIGIN"
      0x33 -> "CALLER"
      0x34 -> "CALLVALUE"
      0x35 -> "CALLDATALOAD"
      0x36 -> "CALLDATASIZE"
      0x37 -> "CALLDATACOPY"
      0x38 -> "CODESIZE"
      0x39 -> "CODECOPY"
      0x3A -> "GASPRICE"
      0x3B -> "EXTCODESIZE"
      0x3C -> "EXTCODECOPY"
      0x3D -> "RETURNDATASIZE"
      0x3E -> "RETURNDATACOPY"
      0x3F -> "EXTCODEHASH"
      0x40 -> "BLOCKHASH"
      0x41 -> "COINBASE"
      0x42 -> "TIMESTAMP"
      0x43 -> "NUMBER"
      0x44 -> "DIFFICULTY"
      0x45 -> "GASLIMIT"
      0x46 -> "CHAINID"
      0x47 -> "SELFBALANCE"
      0x48 -> "BASEFEE"
      0x49 -> "BLOBHASH"
      0x4A -> "BLOBBASEFEE"
      0x4B -> "Invalid"
      0x4C -> "Invalid"
      0x4D -> "Invalid"
      0x4E -> "Invalid"
      0x4F -> "Invalid"
      0x50 -> "POP"
      0x51 -> "MLOAD"
      0x52 -> "MSTORE"
      0x53 -> "MSTORE8"
      0x54 -> "SLOAD"
      0x55 -> "SSTORE"
      0x56 -> "JUMP"
      0x57 -> "JUMPI"
      0x58 -> "PC"
      0x59 -> "MSIZE"
      0x5A -> "GAS"
      0x5B -> "JUMPDEST"
      0x5C -> "TLOAD"
      0x5D -> "TSTORE"
      0x5E -> "MCOPY"
      0x5F -> "PUSH0"
      0x60 -> "PUSH1"
      0x61 -> "PUSH2"
      0x62 -> "PUSH3"
      0x63 -> "PUSH4"
      0x64 -> "PUSH5"
      0x65 -> "PUSH6"
      0x66 -> "PUSH7"
      0x67 -> "PUSH8"
      0x68 -> "PUSH9"
      0x69 -> "PUSH10"
      0x6A -> "PUSH11"
      0x6B -> "PUSH12"
      0x6C -> "PUSH13"
      0x6D -> "PUSH14"
      0x6E -> "PUSH15"
      0x6F -> "PUSH16"
      0x70 -> "PUSH17"
      0x71 -> "PUSH18"
      0x72 -> "PUSH19"
      0x73 -> "PUSH20"
      0x74 -> "PUSH21"
      0x75 -> "PUSH22"
      0x76 -> "PUSH23"
      0x77 -> "PUSH24"
      0x78 -> "PUSH25"
      0x79 -> "PUSH26"
      0x7A -> "PUSH27"
      0x7B -> "PUSH28"
      0x7C -> "PUSH29"
      0x7D -> "PUSH30"
      0x7E -> "PUSH31"
      0x7F -> "PUSH32"
      0x80 -> "DUP1"
      0x81 -> "DUP2"
      0x82 -> "DUP3"
      0x83 -> "DUP4"
      0x84 -> "DUP5"
      0x85 -> "DUP6"
      0x86 -> "DUP7"
      0x87 -> "DUP8"
      0x88 -> "DUP9"
      0x89 -> "DUP10"
      0x8A -> "DUP11"
      0x8B -> "DUP12"
      0x8C -> "DUP13"
      0x8D -> "DUP14"
      0x8E -> "DUP15"
      0x8F -> "DUP16"
      0x90 -> "SWAP1"
      0x91 -> "SWAP2"
      0x92 -> "SWAP3"
      0x93 -> "SWAP4"
      0x94 -> "SWAP5"
      0x95 -> "SWAP6"
      0x96 -> "SWAP7"
      0x97 -> "SWAP8"
      0x98 -> "SWAP9"
      0x99 -> "SWAP10"
      0x9A -> "SWAP11"
      0x9B -> "SWAP12"
      0x9C -> "SWAP13"
      0x9D -> "SWAP14"
      0x9E -> "SWAP15"
      0x9F -> "SWAP16"
      0xA0 -> "LOG0"
      0xA1 -> "LOG1"
      0xA2 -> "LOG2"
      0xA3 -> "LOG3"
      0xA4 -> "LOG4"
      0xA5 -> "Invalid"
      0xA6 -> "Invalid"
      0xA7 -> "Invalid"
      0xA8 -> "Invalid"
      0xA9 -> "Invalid"
      0xAA -> "Invalid"
      0xAB -> "Invalid"
      0xAC -> "Invalid"
      0xAD -> "Invalid"
      0xAE -> "Invalid"
      0xAF -> "Invalid"
      0xB0 -> "PUSH"
      0xB1 -> "DUP"
      0xB2 -> "SWAP"
      0xB3 -> "Invalid"
      0xB4 -> "Invalid"
      0xB5 -> "Invalid"
      0xB6 -> "Invalid"
      0xB7 -> "Invalid"
      0xB8 -> "Invalid"
      0xB9 -> "Invalid"
      0xBA -> "Invalid"
      0xBB -> "Invalid"
      0xBC -> "Invalid"
      0xBD -> "Invalid"
      0xBE -> "Invalid"
      0xBF -> "Invalid"
      0xC0 -> "Invalid"
      0xC1 -> "Invalid"
      0xC2 -> "Invalid"
      0xC3 -> "Invalid"
      0xC4 -> "Invalid"
      0xC5 -> "Invalid"
      0xC6 -> "Invalid"
      0xC7 -> "Invalid"
      0xC8 -> "Invalid"
      0xC9 -> "Invalid"
      0xCA -> "Invalid"
      0xCB -> "Invalid"
      0xCC -> "Invalid"
      0xCD -> "Invalid"
      0xCE -> "Invalid"
      0xCF -> "Invalid"
      0xD0 -> "Invalid"
      0xD1 -> "Invalid"
      0xD2 -> "Invalid"
      0xD3 -> "Invalid"
      0xD4 -> "Invalid"
      0xD5 -> "Invalid"
      0xD6 -> "Invalid"
      0xD7 -> "Invalid"
      0xD8 -> "Invalid"
      0xD9 -> "Invalid"
      0xDA -> "Invalid"
      0xDB -> "Invalid"
      0xDC -> "Invalid"
      0xDD -> "Invalid"
      0xDE -> "Invalid"
      0xDF -> "Invalid"
      0xE0 -> "Invalid"
      0xE1 -> "Invalid"
      0xE2 -> "Invalid"
      0xE3 -> "Invalid"
      0xE4 -> "Invalid"
      0xE5 -> "Invalid"
      0xE6 -> "Invalid"
      0xE7 -> "Invalid"
      0xE8 -> "Invalid"
      0xE9 -> "Invalid"
      0xEA -> "Invalid"
      0xEB -> "Invalid"
      0xEC -> "Invalid"
      0xED -> "Invalid"
      0xEE -> "Invalid"
      0xEF -> "Invalid"
      0xF0 -> "CREATE"
      0xF1 -> "CALL"
      0xF2 -> "CALLCODE"
      0xF3 -> "RETURN"
      0xF4 -> "DELEGATECALL"
      0xF5 -> "CREATE2"
      0xF6 -> "Invalid"
      0xF7 -> "Invalid"
      0xF8 -> "Invalid"
      0xF9 -> "Invalid"
      0xFA -> "STATICCALL"
      0xFB -> "Invalid"
      0xFC -> "Invalid"
      0xFD -> "REVERT"
      0xFE -> "Invalid"
      0xFF -> "SELFDESTRUCT"
    end
  end

  # https://docs.soliditylang.org/en/latest/internals/source_mappings.html
  def sourcemap_decode(line, prev \\ %{})

  def sourcemap_decode([], _), do: []

  def sourcemap_decode([line | rest], prev) do
    fields = String.split(line, ":") ++ ["", "", "", "", "", ""]

    line =
      for {field, i} <- Enum.with_index([:source_offset, :length, :source_file, :jump, :depth]) do
        value =
          if Enum.at(fields, i) == "" do
            Map.get(prev, field)
          else
            if field != :jump do
              String.to_integer(Enum.at(fields, i))
            else
              Enum.at(fields, i)
            end
          end

        {field, value}
      end
      |> Map.new()

    [line | sourcemap_decode(rest, line)]
  end
end


src = "out/DiodeRegistryLight.sol/DiodeRegistryLight.json"
json = File.read!(src) |> Poison.decode!()
[compiler] = Regex.run(~r/[0-9]+\.[0-9]+\.[0-9]+/, json["metadata"]["compiler"]["version"])
sources = json["metadata"]["sources"]

sources =
  for {name, _} <- sources do
    base = Path.basename(name)
    path = "out"

    [id] =
      File.ls!(Path.join(path, base))
      |> Enum.filter(fn file -> String.ends_with?(file, ".json") end)
      |> Enum.map(fn file -> String.split(file, ".") |> hd() end)
      |> Enum.uniq()
      |> Enum.map(fn file ->
        info =
          Enum.find(
            [
              "#{Path.join(path, base)}/#{file}.#{compiler}.json",
              "#{Path.join(path, base)}/#{file}.json"
            ],
            &File.exists?/1
          )
          |> File.read!()
          |> Poison.decode!()

        info["id"]
      end)
      |> Enum.uniq()

    {id, name}
  end
  |> Map.new()


IO.inspect(sources)

# input = json["deployedBytecode"]
input = File.read!("debug_input_registry3.json") |> Poison.decode!()
sources = input["fileMap"] |> Enum.map(fn {key, value} -> {String.to_integer(key), value} end) |> Map.new()


"0x" <> hex = input["object"]
object = Debug.op_decode(Base.decode16!(hex, case: :mixed))
source_map = input["sourceMap"]

source_map =
  String.split(source_map, ";", trim: false)
  |> Debug.sourcemap_decode()
  |> Enum.map(fn map = %{source_file: index} ->
    case Map.get(sources, index) do
      nil ->
        map

      source_file ->
        len = min(map[:length], 80)
        source = String.slice(File.read!(source_file), map[:source_offset], len)

        map
        |> Map.put(:source_file_name, source_file)
        |> Map.put(:source, source)
    end
  end)

Enum.map(source_map, fn map -> map[:source_file] end)
  |> Enum.uniq()
  |> IO.inspect(label: "source_map")

size = min(length(object), length(source_map))

Enum.zip(Enum.take(object, size), Enum.take(source_map, size))
|> Enum.with_index()
|> Enum.each(fn {op, map} -> IO.inspect({op, map}) end)

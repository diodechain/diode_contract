#! /usr/bin/elixir

dst = "sigs.txt"
File.rm(dst)

File.ls!("build/contracts/")
|> Enum.map(fn file ->
  contract =
    File.read!("build/contracts/#{file}")
    |> Poison.decode!()

  abi =
    Enum.filter(contract["abi"], fn obj -> obj["type"] == "function" end)
    |> Enum.map(fn fun ->
      name = fun["name"]
      types = Enum.map(fun["inputs"], fn input -> input["type"] end)
      spec = ABI.encode_spec(name, types)
      "#{Base16.encode(spec)} #{name}(#{Enum.join(types, ",")})\n"
    end)

  # todo extract tuple names
  # https://stackoverflow.com/questions/51757569/how-solidity-make-function-signature-with-tuplenested-abi
  ast =
    contract["ast"]["nodes"]
    |> Enum.filter(fn node -> node["nodeType"] == "ContractDefinition" end)
    |> Enum.map(fn contract ->
      Enum.filter(contract["nodes"], fn node ->
        node["nodeType"] == "FunctionDefinition" and node["name"] != ""
      end)
    end)
    |> List.flatten()
    |> Enum.map(fn fun ->
      name = fun["name"]
      types = Enum.map(fun["parameters"]["parameters"], fn p -> p["typeName"]["name"] end)
      {name, types}
    end)
    # |> Enum.filter(fn {name, types} -> Enum.all?(types, fn type -> String.downcase(type) == type end))
    |> Enum.map(fn {name, types} ->
      spec = ABI.encode_spec(name, types)
      "#{Base16.encode(spec)} #{name}(#{Enum.join(types, ",")})\n"
    end)

  ast ++ abi
end)
|> List.flatten()
|> Enum.sort()
|> Enum.uniq()
|> Enum.each(fn entry ->
  File.write!(dst, entry, [:append])
end)

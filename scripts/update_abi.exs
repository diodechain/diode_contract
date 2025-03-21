#! /usr/bin/env elixir
Mix.install([:jason])

{_, 0} = System.cmd("forge", ["compile"])

defmodule Abi do
  def update(source, destination) do
    abi = File.read!("out/#{source}.sol/#{source}.json")
    |> Jason.decode!()
    |> Map.get("abi")
    |> Jason.encode!(pretty: true)


    File.write!("ui/js/#{destination}-abi.js", "export default #{abi};")
  end
end


Abi.update("ZTNAPerimeterRegistry", "registry")
Abi.update("ZTNAPerimeterContract", "perimeter")
Abi.update("ZTNAWallet", "wallet")

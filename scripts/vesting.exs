#!/usr/bin/env elixir

defmodule VestingContract do
  defstruct [:ref, :destination, :amount, :start, :duration, :cliff_duration, :revocable]

  def parse(_ref, _amount, _revocable, _destination, "NA") do
    nil
  end

  def parse(ref, amount, revocable, destination, contract) do
    data =
      String.split(String.trim(contract), ";", trim: true)
      |> Enum.map(fn field ->
        [key, value] = String.split(field, ":", trim: true)
        {String.trim(String.downcase(key)), String.trim(value)}
      end)
      |> Enum.into(%{})

    start = to_epoch(data["start"])
    vesting_end = to_epoch(data["end"])
    cliff_end = to_epoch(data["cliff"])

    amount =
      if String.ends_with?(data["amount"], "%") do
        percentage = String.trim(data["amount"], "%") |> String.to_integer()
        trunc(amount * (percentage / 100))
      else
        data["amount"] |> String.to_integer()
      end

    cliff_duration = cliff_end - start
    duration = vesting_end - start

    revocable =
      case String.downcase(revocable) do
        "revocable" -> true
        "unrevocable" -> false
      end

    %VestingContract{
      ref: ref,
      destination: destination,
      amount: amount,
      start: start,
      duration: duration,
      cliff_duration: cliff_duration,
      revocable: revocable
    }
  end

  def to_epoch(date) do
    DateTime.new!(
      Date.from_iso8601!(String.replace(date, "/", "-")),
      Time.from_iso8601!("00:00:00")
    )
    |> DateTime.to_unix()
  end

  def cmd(nil), do: ""

  def cmd(%VestingContract{
        ref: _ref,
        destination: destination,
        amount: _amount,
        start: start,
        duration: duration,
        cliff_duration: cliff_duration,
        revocable: revocable
      }) do
    args = [destination, start, cliff_duration, duration, revocable] |> Enum.join(" ")

    "./scripts/deploy_moonbeam.sh contracts/TokenVesting.sol:TokenVesting --constructor-args #{args}"
  end
end

separator = "\t"
[fields, vestings] = File.read!("vestings.txt")
  |> String.split("\n", trim: true)

fields = String.split(fields, separator, trim: true) |> Enum.map(&String.downcase/1)

for row <- vestings do
  row = List.zip([fields, String.split(row, separator, trim: true)]) |> Map.new()

  ref = String.to_integer(row["ref"])
  amount = String.to_integer(String.replace(row["amount"], ",", ""))
  revocable = row["revocable"] == "Revocable"

  IO.puts("\nref: #{ref} amount: #{amount} revocable: #{revocable} destination: #{destination}")
  vesting1 = VestingContract.parse(ref, amount, revocable, destination)
  IO.puts(VestingContract.cmd(vesting1))
  vesting2 = VestingContract.parse(ref, amount, revocable, destination)
  IO.puts(VestingContract.cmd(vesting2))
end

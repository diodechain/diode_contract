#!/usr/bin/env elixir

defmodule VestingContract do
  defstruct [:ref, :destination, :amount, :start, :duration, :cliff_duration, :revocable]

  def parse(_ref, _amount, _revocable, _destination, "NA") do
    nil
  end

  def parse(ref, amount, revocable, destination, row) do
    start = to_linux_timestamp(row["start"])

    # TODO: Lock is already encoded in the start date
    # start = case row["lock"] do
    #   "None" -> start
    #   months ->
    #     if String.ends_with?(months, "mo") do
    #       months = String.trim_trailing(months, "mo") |> String.to_integer()
    #       start + months * 30 * 24 * 60 * 60
    #     else
    #       raise "Invalid lock duration: #{row["lock"]}"
    #     end
    # end

    vesting_end = to_linux_timestamp(row["end"])
    cliff_end = to_linux_timestamp(row["cliff"]) || start

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

  def to_linux_timestamp("None"), do: nil
  def to_linux_timestamp(date) do
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
[fields | vestings] = File.read!("vestings.txt")
  |> String.split("\n", trim: true)

fields = String.split(fields, separator, trim: true) |> Enum.map(&String.downcase/1)

for row <- vestings do
  row = Enum.zip([fields, String.split(row, separator, trim: true)]) |> Map.new()

  ref = String.to_integer(row["ref"])
  amount = String.to_integer(String.replace(row["amount"], ",", ""))
  revocable = row["revocable"]
  destination = row["destination"]
  IO.puts("\n# ref: #{ref} amount: #{amount} revocable: #{revocable} destination: #{destination}")
  vesting1 = VestingContract.parse(ref, amount, revocable, destination, row)
  IO.puts(VestingContract.cmd(vesting1))
end

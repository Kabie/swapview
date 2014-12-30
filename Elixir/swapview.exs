#!/usr/bin/env elixir

defmodule Swapview do

  @regex_swap ~r/Swap:\s*(\d+)/

  def filter_pid(dir) do
    Regex.match?(~r"\A\d+\z", dir) && File.dir?(dir)
  end

  def read_smaps(pid) do
    "/proc/#{pid}/smaps"
    |> File.open!
    |> IO.read(:all)
  end

  def filter_error({:error, _}), do: false
  def filter_error(_), do: true

  def get_swap_size(content) do
    @regex_swap
    |> Regex.scan(content)
    |> Enum.map(fn
      [_, size] -> String.to_integer(size)
    end)
    |> Enum.reduce(0, &+/2)
  end

  def filter_zero(0), do: false
  def filter_zero(_), do: true

  def format_line(n) do
    n
  end

  def reduce_result(result, acc) do
    [result | acc]
  end
  
  def run do
    "/proc"
    |> File.cd!(fn ->
      File.ls!
      |> Enum.filter_map(&filter_pid/1, &read_smaps/1)
      |> Enum.filter_map(&filter_error/1, &get_swap_size/1)
      |> Enum.filter_map(&filter_zero/1, &format_line/1)
      |> Enum.reduce([], &reduce_result/2)
      |> Enum.each(&IO.inspect/1)
    end)
  end
  
end

Swapview.run

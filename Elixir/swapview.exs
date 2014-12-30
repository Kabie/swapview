#!/usr/bin/env elixir

defmodule Swapview do
  use Bitwise

  @regex_swap ~r/Swap:\s*(\d+)/

  defp filter_pid(dir) do
    Regex.match?(~r"\A\d+\z", dir) && File.dir?(dir)
  end

  defp read_smaps(pid) do
    cmd = "/proc/#{pid}/cmdline"
    |> File.open!
    |> IO.read(:all)

    "/proc/#{pid}/smaps"
    |> File.open!([:read], fn file ->
      file
      |> IO.read(:all)
      |> (fn
        {:error, _} -> {pid, 0, cmd}
        content -> {pid, get_swap_size(content), cmd}
      end).()
    end)
  end

  defp get_swap_size(content) do
    @regex_swap
    |> Regex.scan(content)
    |> Enum.map(fn
      [_, size] -> String.to_integer(size)
    end)
    |> Enum.reduce(0, &+/2)
  end

  defp filter_zero({_, 0, _}), do: false
  defp filter_zero(_), do: true

  defp format_line({pid, size, cmd}) do
    "#{pid |> String.rjust(5)} #{size |> format_size |> String.rjust(9)} #{cmd}"
  end

  defp format_size(size), do: format_size(size, ~w(B KiB MiB GiB TiB))
  defp format_size(size, [_|units]) when size > 1100, do: format_size(size >>> 10, units)
  defp format_size(size, [unit|_]), do: "#{size}#{unit}"
  
  def run do
    IO.puts "  PID      SWAP COMMAND"
    "/proc"
    |> File.cd!(fn ->
      total = File.ls!
      |> Enum.filter_map(&filter_pid/1, &read_smaps/1)
      |> Enum.filter(&filter_zero/1)
      |> Enum.reduce(0, fn {_, size, _} = result, acc ->
        result
        |> format_line
        |> IO.puts
        size + acc
      end)
      IO.puts "Total: #{total |> format_size}"
    end)
  end
  
end

Swapview.run

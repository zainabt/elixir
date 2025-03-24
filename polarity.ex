defmodule Polarity do
  @moduledoc """
  Solver for the Polarity Placement Puzzle in Elixir.
  """

  def polarity(board, specs) do
    board = board |> Enum.map(&String.graphemes/1)
    solve(board, specs) |> format_output()
  end

  defp solve(board, specs) do
    solve_helper(board, specs, 0, 0)
  end

  defp solve_helper(board, specs, row, col) do
    case find_empty_tile(board, row, col) do
      nil -> if valid_solution?(board, specs), do: board, else: :no_solution
      {r, c} -> try_placements(board, specs, r, c)
    end
  end

  defp try_placements(board, specs, row, col) do
    possible_placements = [{"+", "-"}, {"-", "+"}]

    Enum.find_value(possible_placements, fn {p1, p2} ->
      if valid_placement?(board, row, col, p1, p2) do
        updated_board = place_magnet(board, row, col, p1, p2)
        solve_helper(updated_board, specs, row, col)
      end
    end) || board
  end

  defp valid_placement?(board, row, col, p1, p2) do
    within_bounds?(board, row, col + 1) and
    Enum.at(Enum.at(board, row), col) == "L" and
    Enum.at(Enum.at(board, row), col + 1) == "R" and
      no_polarity_conflict?(board, row, col, p1, p2)
  end

  defp no_polarity_conflict?(board, row, col, p1, p2) do
    adjacent = [
      {row - 1, col}, {row + 1, col}, {row, col - 1}, {row, col + 2}
    ]
    Enum.all?(adjacent, fn {r, c} ->
      within_bounds?(board, r, c) and Enum.at(Enum.at(board, r), c) not in [p1, p2]
    end)
  end

  defp valid_solution?(board, specs) do
    check_constraints(board, specs, :left) and
    check_constraints(board, specs, :right) and
    check_constraints(board, specs, :top) and
    check_constraints(board, specs, :bottom)
  end

  defp check_constraints(board, specs, direction) do
    constraints = Map.get(specs, Atom.to_string(direction), [])
    board_values = extract_values(board, direction)
    Enum.zip(board_values, constraints) |> Enum.all?(fn {count, expected} -> expected == -1 or count == expected end)
  end

  defp extract_values(board, :left), do: Enum.map(board, fn row -> Enum.count(row, fn x -> x == "+" end) end)
  defp extract_values(board, :right), do: Enum.map(board, fn row -> Enum.count(row, fn x -> x == "-" end) end)
  defp extract_values(board, :top), do: Enum.map(transpose(board), fn col -> Enum.count(col, fn x -> x == "+" end) end)
  defp extract_values(board, :bottom), do: Enum.map(transpose(board), fn col -> Enum.count(col, fn x -> x == "-" end) end)

  defp transpose(list), do: list |> Enum.zip() |> Enum.map(&Tuple.to_list/1)

  defp find_empty_tile(board, row, col) do
    for r <- row..(length(board) - 1), c <- col..(length(Enum.at(board, r)) - 1),
        Enum.at(Enum.at(board, r), c) in ["L", "R"] do
      {r, c}
    end |> List.first()
  end

  defp place_magnet(board, row, col, p1, p2) do
    List.update_at(board, row, fn line ->
      List.replace_at(line, col, p1) |> List.replace_at(col + 1, p2)
    end)
  end

  defp within_bounds?(board, row, col),
    do: row in 0..(length(board) - 1) and col in 0..(length(Enum.at(board, 0)) - 1)

  defp format_output(board) do
    Enum.map(board, &Enum.join(&1, ""))
  end
end

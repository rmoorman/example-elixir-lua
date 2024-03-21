defmodule ExampleTest do
  use ExUnit.Case

  @event %{
    "text" => "How many points do you want?",
    "choices" => [
      %{"value" => 3, "text" => "3"},
      %{"value" => 2, "text" => "2"},
      %{"value" => 1, "text" => "1"}
    ],
    "script" => """
    for player, choice in pairs(s.made_choices) do
      local points = s.event.choices[choice].value
      s.add_points(player, points)
      s.add_message(player, "Nice! You got yourself " .. points .. " points!")
    end
    """
  }

  @made_choices %{"foo" => 0}

  @prelude """
  __actions = {}

  function s.add_points(player, points)
    table.insert(__actions, {"add_points", player, points})
  end

  function s.add_message(player, message)
    table.insert(__actions, {"add_message", player, tostring(message)})
  end
  """

  test "roughly how I used sandbox somewhere" do
    result =
      Sandbox.init()
      |> Sandbox.set!("s", %{})
      |> Sandbox.set!(["s", "event"], @event)
      |> Sandbox.set!(["s", "made_choices"], table_idx_fix(@made_choices))
      |> Sandbox.play!(@prelude)
      |> Sandbox.play!(@event["script"])
      |> Sandbox.eval("return __actions")
      |> then(fn {:ok, result} -> sandbox_table_to_list(result) end)

    assert result == [
             ["add_points", "foo", 3.0],
             ["add_message", "foo", "Nice! You got yourself 3 points!"]
           ]
  end

  ###
  ###
  ###

  defp table_idx_fix(map) do
    Enum.into(map, %{}, fn {k, v} -> {k, v + 1} end)
  end

  defp sandbox_table_to_list(value) do
    case value do
      table when is_list(table) -> Enum.map(table, &sandbox_table_to_list/1)
      {_idx, value} -> sandbox_table_to_list(value)
      value -> value
    end
  end
end

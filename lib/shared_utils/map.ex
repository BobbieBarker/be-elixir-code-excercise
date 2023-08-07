defmodule SharedUtils.Map do
  @moduledoc """
  A utility module to make it easier to work with maps
  """
  @whitelisted_modules [DateTime, NaiveDateTime, Date, Time]
  @struct_fields [:__meta__]

  defmodule Address do
    defstruct [:state]
  end

  @doc """
  Changes structs into maps all the way down, excluding
  things like DateTime.

  ### Example

      iex> datetime = DateTime.utc_now()
      iex> naive_datetime = NaiveDateTime.utc_now()
      iex> date = Date.utc_today()
      iex> time = Time.utc_now()
      iex> SharedUtils.Map.deep_struct_to_map(%{
      ...>   a: %SharedUtils.Map.Address{},
      ...>   b: [%{a: datetime, c: 4}],
      ...>   c: date,
      ...>   d: time,
      ...>   e: naive_datetime
      ...> })
      %{a: %{state: nil}, b: [%{a: datetime, c: 4}], c: date, d: time, e: naive_datetime}
  """
  @spec deep_struct_to_map(any) :: any
  def deep_struct_to_map(%module{} = struct) when module in @whitelisted_modules do
    struct
  end

  def deep_struct_to_map(struct) when is_struct(struct) do
    struct
    |> Map.from_struct()
    |> Map.drop(@struct_fields)
    |> deep_struct_to_map()
  end

  def deep_struct_to_map(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {k, deep_struct_to_map(v)} end)
  end

  def deep_struct_to_map(list) when is_list(list) do
    Enum.map(list, &deep_struct_to_map/1)
  end

  def deep_struct_to_map(elem) do
    elem
  end
end

defmodule BeExercise.Support.Factory do
  @moduledoc """
  This module defines an Ecto factory behaviour.

  For defining your own factories just implement `schema/0`, `repo/0` and
  `build/0` callback e.g:

  ```elixir
  defmodule MyFactory do
    @behaviour BeExercise.Support.Factory

    def schema, do: MySchema

    def repo, do: MyRepo

    def build(params \\ %{}) do
      default = %{
        foo: 21,
        bar: 42
      }

      Map.merge(default, params)
    end
  end
  ```

  And then using it in your tests as:

  ```elixir
  # For getting a default parameter map.
  BeExercise.Support.Factory.build(MyFactory)

  # For getting a default parameter map with a modification.
  BeExercise.Support.Factory.build(MyFactory, foo: 42)

  # For inserting a default schema.
  BeExercise.Support.Factory.insert!(MyFactory)

  # For inserting a default schema with a modification.
  BeExercise.Support.Factory.insert!(MyFactory, foo: 42)

  # For inserting a schema without changeset validation.
  BeExercise.Support.Factory.insert!(MyFactory, %{foo: 42}, validate: false)
  ```
  """

  alias Ecto.Changeset

  @doc """
  Callback that returns the schema module.
  """
  @callback schema() :: module()

  @doc """
  Callback that returns the schema's repo module.
  """
  @callback repo() :: module()

  @doc """
  Callback that returns a map with valid defaults for the schema.
  """
  @callback build(map()) :: map()

  @doc """
  Callback that returns a struct with valid defaults for the schema.
  """
  @callback build_struct(map()) :: struct()

  @optional_callbacks [build_struct: 1]

  @doc """
  Builds the parameters for a schema `changeset/2` function given the factory
  `module` and an optional list/map of `params`.
  """
  @spec build_params(module()) :: map()
  @spec build_params(module(), keyword() | map()) :: map()
  def build_params(module, params \\ %{})

  def build_params(module, params) when is_list(params) do
    build_params(module, Map.new(params))
  end

  def build_params(module, params) do
    params
    |> module.build()
    |> SharedUtils.Map.deep_struct_to_map()
  end

  @doc """
  Builds a schema given the factory `module` and an optional
  list/map of `params`.
  """
  @spec build(module()) :: Ecto.Schema.t()
  @spec build(module(), keyword() | map()) :: Ecto.Schema.t()
  def build(module, params \\ %{}, options \\ [])

  def build(module, params, options) when is_list(params) do
    build(module, Map.new(params), options)
  end

  def build(module, params, options) do
    validate = Keyword.get(options, :validate, true)

    params
    |> module.build()
    |> maybe_changeset(module, validate)
    |> case do
      %Changeset{} = changeset -> Changeset.apply_action!(changeset, :insert)
      struct when is_struct(struct) -> struct
    end
  end

  @doc """
  Inserts a schema given the factory `module` and an optional list/map of
  `params`. Fails on error.
  """
  @spec insert!(module()) :: Ecto.Schema.t() | no_return()
  @spec insert!(module(), keyword() | map(), Keyword.t()) :: Ecto.Schema.t() | no_return()
  def insert!(module, params \\ %{}, options \\ [])

  def insert!(module, params, options) when is_list(params) do
    insert!(module, Map.new(params), options)
  end

  def insert!(module, params, options) do
    validate = Keyword.get(options, :validate, true)

    params
    |> module.build()
    |> maybe_changeset(module, validate)
    |> module.repo().insert!(options)
  end

  @doc """
  Insert as many as `count` schemas given the factory `module` and an optional
  list/map of `params`.
  """
  @spec insert_many!(pos_integer(), module()) :: [Ecto.Schema.t()]
  @spec insert_many!(pos_integer(), module(), keyword() | map()) :: [Ecto.Schema.t()]
  def insert_many!(count, module, params \\ %{}, options \\ []) when count > 0 do
    Enum.map(1..count, fn _ -> insert!(module, params, options) end)
  end

  @doc """
  Removes all the instances of a schema from the database given its factory
  `module`.
  """
  @spec cleanup(module) :: {integer(), nil | [term()]}
  def cleanup(module, options \\ []) do
    module.repo().delete_all(module.schema(), options)
  end

  defp maybe_changeset(params, module, validate) do
    if validate && schema?(module) do
      if function_exported?(module.schema(), :create_changeset, 1) do
        params
        |> SharedUtils.Map.deep_struct_to_map()
        |> module.schema().create_changeset()
      else
        params
        |> SharedUtils.Map.deep_struct_to_map()
        |> then(&module.schema().changeset(struct(module.schema()), &1))
      end
    else
      struct!(module.schema, params)
    end
  end

  defp schema?(module) do
    function_exported?(module.schema(), :__schema__, 1)
  end
end

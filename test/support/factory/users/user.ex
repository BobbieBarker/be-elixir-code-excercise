defmodule BeExercise.Support.Factory.Users.User do
  @moduledoc false
  alias BeExercise.Support.Factory

  @behaviour Factory

  @impl Factory
  def schema, do: BeExercise.Users.User

  @impl Factory
  def repo, do: BeExercise.Repo

  @impl Factory
  def build(attrs \\ %{}) do
    %{
      name: Faker.Person.name()
    }
    |> Map.merge(attrs)
  end
end

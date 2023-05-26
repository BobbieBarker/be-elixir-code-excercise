defmodule BeExercise.Support.Factory.Users.Salary do
  @moduledoc false
  alias BeExercise.Support.Factory
  alias Constants.SalaryConstants

  @behaviour Factory

  @impl Factory
  def schema, do: BeExercise.Users.Salary

  @impl Factory
  def repo, do: BeExercise.Repo

  @impl Factory
  def build(attrs \\ %{}) do
    %{
      active: Enum.random([true, false]),
      amount: generate_amount()
    }
    |> Map.merge(attrs)
    |> Map.put_new_lazy(:user_id, fn ->
      user = Factory.insert!(Factory.Users.User)
      user.id
    end)
  end


  defp generate_amount() do
    Money.new(
      Enum.random(1..5000),
      Enum.random(SalaryConstants.supported_currencies())
    )
  end
end

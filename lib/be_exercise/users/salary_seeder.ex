defmodule BeExercise.Users.SalarySeeder do
  alias BeExercise.Repo
  alias BeExercise.{Users, Users.Salary}
  alias Constants.SalaryConstants

  def random_salary(attrs \\ %{}) do
    {:ok, _salary} = attrs
    |> random_salary_attributes()
    |> Users.create_salary()
  end

  def random_salaries(user, count) do
    1..count
    |> Enum.map(fn _ -> random_salary_attributes(%{user_id: user.id}) end)
    |> then(&Repo.insert_all(Salary, &1, on_conflict: :nothing))
  end

  defp random_salary_attributes(attrs) do
    Map.merge(%{
      active: Enum.random([true, false]),
      amount: Money.new(
        Enum.random(1..100_000),
        Enum.random(SalaryConstants.supported_currencies())
      ),
      inserted_at: DateTime.utc_now(),
      updated_at:  DateTime.utc_now()
    }, attrs)
  end
end

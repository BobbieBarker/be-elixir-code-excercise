defmodule BeExercise.Users.UserSeeder do
  @moduledoc false

  alias BeExercise.Repo
  alias BeExercise.{
    Users,
    Users.User,
    Users.SalarySeeder
  }

  def random_user(attrs \\ %{}) do
    {:ok, _user} = attrs
    |> random_user_attributes()
    |> Users.create_user()
  end

  def random_users(count) do
    1..count
    |> Enum.map(fn _ -> random_user_attributes() end)
    |> then(&Repo.insert_all(User, &1, returning: true))
    |> seed_salaries()
  end

  defp random_user_attributes(attrs \\ %{}) do
    Map.merge(
      %{
        name: Faker.Person.name(),
        inserted_at: DateTime.utc_now(),
        updated_at:  DateTime.utc_now()
      },
      attrs
    )
  end

  # note: I am aware the instructions said to only create 2 salaries per user,
  # but I tend to think things are more interesting with more data.
  defp seed_salaries({_, users}) do
    users
    |> Task.async_stream(
      SalarySeeder,
      :random_salaries,
      [Enum.random(1..5)],
      max_concurrency: 20
    )
    |> Stream.run()
  end
end

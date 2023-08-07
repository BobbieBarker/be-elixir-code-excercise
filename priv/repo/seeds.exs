
alias BeExercise.Users.{User, Salary, UserSeeder}

default_user_seed_count = 20_000

if Mix.env() == :dev do
  BeExercise.Repo.delete_all(Salary)
  BeExercise.Repo.delete_all(User)

  UserSeeder.random_users(default_user_seed_count)
end

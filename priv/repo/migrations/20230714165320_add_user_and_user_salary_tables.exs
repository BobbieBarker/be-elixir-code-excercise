defmodule BeExercise.Repo.Migrations.AddUserAndUserSalaryTables do
  use Ecto.Migration

  @disable_ddl_transaction true
  @disable_migration_lock true

  def change do
    create_if_not_exists table(:users) do
      add :name, :text, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create_if_not_exists table(:user_salaries) do

      add :amount, :money_with_currency
      add :active, :boolean
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps(type: :utc_datetime_usec)
    end

    create_if_not_exists index(
      :user_salaries,
      [:active, :user_id],
      concurrently: true,
      where: "active = false"
    )

    create_if_not_exists unique_index(
      :user_salaries,
      [:active, :user_id],
      concurrently: true,
      where: "active = true",
      name: "user_salaries_active_user_true_id_index"
    )
  end
end

defmodule BeExercise.Repo.Migrations.AddMoneyWithCurrencyPgType do
  @moduledoc """
  This module adds a custom type "money_with_currency" to the database. Custom
  types are very similar to json except that they give us greater data integrity/structure.
  """

  use Ecto.Migration


  def up do
    execute """
    CREATE TYPE public.money_with_currency AS (amount integer, currency varchar(3))
    """
  end

  def down do
    execute """
    DROP TYPE public.money_with_currency
    """
  end
end

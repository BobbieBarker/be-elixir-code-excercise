defmodule BeExercise.Users.SalaryTest do
  @moduledoc false

  use BeExercise.DataCase, async: true

  alias BeExercise.Support.Factory

  alias BeExercise.Users.Salary

  describe "&create_changeset/1" do
    test "can create a valid changeset" do
      changeset =
        Factory.Users.Salary
        |> Factory.build_params()
        |> Salary.create_changeset()

      assert changeset.valid?
    end

    test "returns an error for unsupported currencies" do
      changeset =
        Factory.Users.Salary
        |> Factory.build_params(%{amount: %{amount: 2, currency: :ccc}})
        |> Salary.create_changeset()

      assert %Ecto.Changeset{
        errors: [amount: {"must use a supported currency", []}]
      } = changeset
    end

    test "returns an error for invalid salary amounts" do
      changeset =
        Factory.Users.Salary
        |> Factory.build_params(%{amount: %{amount: -2, currency: :USD}})
        |> Salary.create_changeset()

      assert %Ecto.Changeset{
        errors: [amount: {"amount must be greater than zero", []}]
      } = changeset
    end

    test "valid salary will insert" do
      assert {:ok, _} = Factory.Users.Salary
      |> Factory.build_params()
      |> Salary.create_changeset()
      |> Repo.insert()
    end

    test "user cannot have more than one active salary" do
      assert {:ok, salary} = Factory.Users.Salary
      |> Factory.build_params(%{active: true})
      |> Salary.create_changeset()
      |> Repo.insert()

      assert {
        :error,
        %Ecto.Changeset{
          errors: [active: {"a user can only have one active salary at a time", _}]
        }
      } = Factory.Users.Salary
      |> Factory.build_params(%{active: true, user_id: salary.user_id})
      |> Salary.create_changeset()
      |> Repo.insert()
    end
  end
end

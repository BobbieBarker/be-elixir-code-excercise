defmodule BeExercise.Users.UserTest do
  @moduledoc false

  use BeExercise.DataCase, async: true

  alias BeExercise.Support.Factory
  alias BeExercise.Users.User

  describe "&create_changeset/1" do
    test "can create a valid changeset" do
      changeset =
        Factory.Users.User
        |> Factory.build_params()
        |> User.create_changeset()

      assert changeset.valid?
    end

    test "valid user will insert" do
      assert {:ok, _} = Factory.Users.User
      |> Factory.build_params()
      |> User.create_changeset()
      |> Repo.insert()
    end
  end
end

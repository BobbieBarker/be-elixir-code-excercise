defmodule BeExercise.UsersTest do
  use BeExercise.DataCase, async: true
  @moduledoc false

  alias BeExercise.Users
  alias BeExercise.Users.{User, Salary}
  alias BeExercise.Support.Factory

  import Mox
  import ExUnit.CaptureLog

  describe "create and update user functions" do
    test "&create_user/1 && update_user/2" do
      attrs = Factory.build_params(Factory.Users.User)
      assert {:ok, %User{} = user} = Users.create_user(attrs)

      assert {:error, _} = Users.create_user(%{})

      assert {:ok, %User{} = updated} =
        Users.update_user(user, %{name: Faker.Person.first_name()})

      assert updated.id === user.id

      assert {:ok, %User{}} =
        Users.update_user(user.id, %{name: Faker.Person.first_name()})
    end
  end

  describe "find user functions" do
    test "&find_user/1" do
      user = Factory.insert!(Factory.Users.User)

      assert {:ok, res_user} = Users.find_user(%{id: user.id})

      assert res_user.id === user.id
    end

    test "&all_users/1" do
      user1 = Factory.insert!(Factory.Users.User)
      user2 = Factory.insert!(Factory.Users.User)

      [res_user1, res_user2] = Users.all_users()

      assert res_user1.id === user1.id
      assert res_user2.id === user2.id
    end

    test "&find_recent_and_active_salaries/1 can return recent salary info" do
      user1 = Factory.insert!(Factory.Users.User)
      Factory.insert!(Factory.Users.Salary, %{user_id: user1.id, active: true})
      Factory.insert!(Factory.Users.Salary, %{user_id: user1.id, active: false})

      user2 = Factory.insert!(Factory.Users.User)

      salary1 = Factory.insert!(Factory.Users.Salary, %{user_id: user2.id, active: false})
      Factory.insert!(Factory.Users.Salary, %{user_id: user2.id, active: false})

      Users.update_salary(salary1, %{amount: %{amount: 2, currency: :USD}})

      user1_id = user1.id

      user2_id = user2.id

      users = Users.find_recent_and_active_salaries()

      assert [
        %{id: ^user1_id, salary: %{active: true}},
        %{id: ^user2_id, salary: %{active: false, amount: %Money{amount: 2, currency: :USD}}}
      ] = Enum.sort_by(users, & &1.id)
    end

    test "&all_active_users/1 can return all users with active salaries" do
      user1 = Factory.insert!(Factory.Users.User)
      Factory.insert!(Factory.Users.Salary, %{user_id: user1.id, active: true})
      Factory.insert!(Factory.Users.Salary, %{user_id: user1.id, active: false})

      user2 = Factory.insert!(Factory.Users.User)
      Factory.insert!(Factory.Users.Salary, %{user_id: user2.id, active: false})
      Factory.insert!(Factory.Users.Salary, %{user_id: user2.id, active: false})

      assert [user_res] = Users.all_active_users(%{preload: :salaries})

      assert user1.id === user_res.id
    end
  end

  describe "&send_invite_email/1" do
    test "sends an email" do
      user = Factory.insert!(Factory.Users.User)

      expect(
        BeExercise.MockBeChallengeex,
        :send_email,
        fn %User{name: name} -> {:ok, name} end
      )

      assert :ok === Users.send_invite_email(user)
    end

    test "logs errors when email client returns error tuple" do
      user = Factory.insert!(Factory.Users.User)

      expect(
        BeExercise.MockBeChallengeex,
        :send_email,
        fn %User{name: _name} -> {:error, :econnrefused} end
      )

      log_msg = "failed to send invitation email to: #{user.id}"

      capture_log(fn ->
        assert :ok === Users.send_invite_email(user)
      end) =~ log_msg
    end
  end

  describe "delete user functions" do
    test "&delete_user/1" do
      user = Factory.insert!(Factory.Users.User)
      assert {:ok, _} = Users.find_user(%{id: user.id})

      assert {:ok, _} = Users.delete_user(user)

      assert {:error, %ErrorMessage{code: :not_found}} = Users.find_user(%{id: user.id})
    end
  end

  #####

  describe "create and update user salary functions" do
    test "&create_salary/1 && update_salary/2" do
      attrs = Factory.build_params(Factory.Users.Salary, %{active: true})
      assert {:ok, %Salary{active: true} = salary} = Users.create_salary(attrs)

      assert {:error, _} = Users.create_salary(%{})

      assert {:ok, %Salary{active: false} = updated} =
        Users.update_salary(salary, %{active: false})

      assert updated.id === salary.id

      assert {:ok, %Salary{active: true}} =
        Users.update_salary(salary.id, %{active: true})
    end
  end

  describe "find user salary functions" do
    test "&find_salary/1" do
      salary = Factory.insert!(Factory.Users.Salary)

      assert {:ok, res_salary} = Users.find_salary(%{id: salary.id})

      assert res_salary.id === salary.id
    end

    test "&all_salaries/1" do
      salary1 = Factory.insert!(Factory.Users.Salary)
      salary2 = Factory.insert!(Factory.Users.Salary)

      [res_salary1, res_salary2] = Users.all_salaries()

      assert res_salary1.id === salary1.id
      assert res_salary2.id === salary2.id
    end
  end

  describe "delete user salary functions" do
    test "&delete_salary/1" do
      salary = Factory.insert!(Factory.Users.Salary)
      assert {:ok, _} = Users.find_salary(%{id: salary.id})

      assert {:ok, _} = Users.delete_salary(salary)

      assert {:error, %ErrorMessage{code: :not_found}} = Users.find_salary(%{id: salary.id})
    end
  end
end

defmodule BeExerciseWeb.UserControllerTest do
  @moduledoc false

  alias BeExercise.Support.Factory
  alias BeExercise.{SchemaCache, Users, Users.User}

  use BeExerciseWeb.ConnCase, async: false
  import Mox

  setup do
    Cache.SandboxRegistry.register_caches(SchemaCache.Repo.Redis)
  end

  describe "&index/2" do
    test "indexes the users", %{conn: conn} do
      user1 = Factory.insert!(Factory.Users.User, %{name: "a"})
      Factory.insert!(Factory.Users.Salary, %{user_id: user1.id, active: true})
      Factory.insert!(Factory.Users.Salary, %{user_id: user1.id, active: false})

      user2 = Factory.insert!(Factory.Users.User, %{name: "steve"})

      salary1 = Factory.insert!(Factory.Users.Salary, %{user_id: user2.id, active: false})
      Factory.insert!(Factory.Users.Salary, %{user_id: user2.id, active: false})

      Users.update_salary(salary1, %{amount: %{amount: 2, currency: :USD}})

      resp = get(
        conn,
        ~p"/users?order[name]=desc"
      )

      assert [
        %{"name" => "steve"},
        %{"name" => "a"}
      ] = json_response(resp, 200)
    end

    test "filters by user name", %{conn: conn} do
      user1 = Factory.insert!(Factory.Users.User)
      Factory.insert!(Factory.Users.Salary, %{user_id: user1.id, active: true})
      Factory.insert!(Factory.Users.Salary, %{user_id: user1.id, active: false})

      user2 = Factory.insert!(Factory.Users.User, %{name: "steve"})

      salary1 = Factory.insert!(Factory.Users.Salary, %{user_id: user2.id, active: false})
      Factory.insert!(Factory.Users.Salary, %{user_id: user2.id, active: false})

      Users.update_salary(salary1, %{amount: %{amount: 2, currency: :USD}})

      resp = get(
        conn,
        ~p"/users?filter[name]=steve"
      )

      assert [
        %{
          "name" => "steve",
          "salary" => %{
            "active" => false,
            "amount" => %{
              "amount" => 2,
              "currency" => "USD"
            }
          }
        }
      ] = json_response(resp, 200)
    end
  end


  describe "&invite_users/2" do
    setup :verify_on_exit!

    test "sends invites to users", %{conn: conn} do
      user1 = Factory.insert!(Factory.Users.User)
      Factory.insert!(Factory.Users.Salary, %{user_id: user1.id, active: true})
      Factory.insert!(Factory.Users.Salary, %{user_id: user1.id, active: false})

      parent = self()
      ref = make_ref()

      expect(
        BeExercise.MockBeChallengeex,
        :send_email,
        1,
        fn %User{name: name} ->
          send(parent, {ref, :temp})
          {:ok, name}
        end
      )

      resp = post(
        conn,
        ~p"/invite-users",
        %{}
      )

      assert response(resp, 204)

      assert_receive {^ref, :temp}
    end
  end
end

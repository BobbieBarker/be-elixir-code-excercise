defmodule BeExercise.Users do
  @moduledoc """
  Context module used to expose an API for performing CRUD operations
  against User resources.
  """
  import Ecto.Query

  alias BeExercise.Users.{User, Salary}
  alias EctoShorts.Actions
  alias BeExercise.{Metrics, Config, Repo, SchemaCache}

  @allowed_sorting_directions ["asc", "desc"]

  @recent_or_active_user_salaries_key "recent_or_active_user_salaries"
  @recent_or_active_user_salaries_ttl :timer.minutes(30)

  require Logger

  @type find_res(schema) :: ErrorMessage.t_res(schema)
  @type change_res(schema) :: BeExercise.t_res(schema)
  @type id :: pos_integer

  @spec create_user(map) :: change_res(User.t())
  def create_user(params) do
    Actions.create(User, params)
  end

  @doc false
  @spec update_user(id | User.t(), map) :: change_res(User.t())
  def update_user(%User{} = user, params) do
    Actions.update(User, user, params)
  end

  def update_user(user_id, params) when is_integer(user_id) do
    Actions.update(User, user_id, params)
  end

  @spec find_user(map) :: find_res(User.t)
  def find_user(params) do
    Actions.find(User, params)
  end

  @spec all_users(map) :: [User.t]
  def all_users(params \\ %{}) do
    Actions.all(User, params)
  end

  @spec all_active_users(map) :: [User.t]
  def all_active_users(params \\ %{}) do
    User.from()
    |> User.join_active_salaries()
    |> Actions.all(params)
  end

  @spec delete_user(User.t) :: change_res(User.t)
  def delete_user(%User{} = user) do
    Actions.delete(user)
  end

  @spec create_salary(map) :: change_res(Salary.t())
  def create_salary(params) do
    Actions.create(Salary, params)
  end

  @doc false
  @spec update_salary(id | Salary.t(), map) :: change_res(Salary.t())
  def update_salary(%Salary{} = salary, params) do
    Actions.update(Salary, salary, params)
  end

  def update_salary(salary_id, params) when is_integer(salary_id) do
    Actions.update(Salary, salary_id, params)
  end

  @spec find_salary(map) :: find_res(Salary.t)
  def find_salary(params) do
    Actions.find(Salary, params)
  end

  @spec all_salaries(map) :: [Salary.t]
  def all_salaries(params \\ %{}) do
    Actions.all(Salary, params)
  end

  @spec delete_salary(Salary.t) :: change_res(Salary.t)
  def delete_salary(%Salary{} = salary) do
    Actions.delete(salary)
  end

  @spec find_recent_and_active_salaries(map) :: [User.t]
  def find_recent_and_active_salaries(params \\ %{}) do
    users_with_active_salaries =
      User.join_active_salaries()
      |> User.maybe_filter_by_name(params)
      |> User.select_user_salary_attrs()

    users_with_no_active_salaries =
      User.distinct_by(:id)
      |> User.join_inactive_salaries()
      |> User.where_salary_not_active()
      |> User.maybe_filter_by_name(params)
      |> Salary.order_by_last_updated_at()
      |> User.select_user_salary_attrs()

    users_with_active_salaries
    |> union(^users_with_no_active_salaries)
    |> Repo.all()
    |> maybe_sort_by_user_name(params)
  end

  @spec cached_find_recent_and_active_salaries(map) :: [User.t]
  def cached_find_recent_and_active_salaries(params \\ %{}) do
    SchemaCache.repo_redis_get_or_fetch_by_params(
      @recent_or_active_user_salaries_key,
      params,
      @recent_or_active_user_salaries_ttl,
      fn -> find_recent_and_active_salaries(params) end
    )
  end

  @spec send_invite_email(User.t) :: :ok
  def send_invite_email(%User{} = user) do
    case Config.be_challengeex().send_email(user) do
      {:ok, _} ->
        Metrics.incr_invitation_success()
        :ok
      {:error, reason} ->
        Metrics.incr_invitation_failure()

        Logger.warn(%{
          message: "failed to send invitation email to: #{user.id}",
          reason: reason
        })
    end
  end

  defp maybe_sort_by_user_name(
    users,
    %{"order" => %{"name" => direction}}
  ) when direction in @allowed_sorting_directions do
    Enum.sort_by(users, & &1.name, String.to_existing_atom(direction))
  end

  defp maybe_sort_by_user_name(users, _params), do: users
end

defmodule BeExercise.Users.User do
  @moduledoc """
  This table is used to store user info. A user has a name and can have
  multiple salaries, though only one salary should be active at any given time.
  """

  use BeExercise

  alias BeExercise.Users.Salary

  @type t :: %__MODULE__{
    id: pos_integer() | nil,
    name: String.t,
    salaries: [Salary.t()] | Ecto.Association.NotLoaded.t(),
    updated_at: DateTime.t() | nil,
    inserted_at: DateTime.t() | nil
  }

  @type query :: Ecto.Query.t()
  @type queryable :: Ecto.Queryable.t()


  @required [:name]
  @allowed @required

  @enforce_keys @required

  @derive {Jason.Encoder, only: [:name, :salary]}
  schema "users" do
    field :name, :string

    has_many :salaries, Salary
    field :salary, :map, virtual: true

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  @spec create_changeset(map) :: Ecto.Changeset.t()
  def create_changeset(attrs) do
    @enforce_keys
    |> Map.new(&{&1, nil})
    # note: using a struct like this gives our code some compile time checks.
    |> then(&struct!(__MODULE__, &1))
    |> changeset(attrs)
  end

  @doc false
  @spec changeset(t()) :: Ecto.Changeset.t(t)
  @spec changeset(t(), map()) :: Ecto.Changeset.t(t)
  def changeset(%__MODULE__{} = salary, params \\ %{}) do
    salary
    |> cast(params, @allowed)
    |> validate_required(@required)
  end

  @doc false
  @spec from() :: query
  @spec from(queryable) :: query
  def from(query \\ __MODULE__), do: from(u in query, as: :user)

  @spec join_active_salaries(queryable()) :: query()
  def join_active_salaries(query \\ from()) do
    join(
      query,
      :inner,
      [user: u],
      s in Salary,
      on: s.user_id == u.id and s.active == true,
      as: :salary
    )
  end

  @spec join_inactive_salaries(queryable()) :: query()
  def join_inactive_salaries(query \\ from()) do
    join(
      query,
      :inner,
      [user: u],
      s in Salary,
      on: s.user_id == u.id and s.active == false,
      as: :salary
    )
  end

  @spec distinct_by(queryable()) :: query()
  def distinct_by(query \\ from(), field) do
    distinct(query, [user: u], [desc: field(u, ^field)])
  end

  @spec where_salary_not_active(queryable()) :: query()
  def where_salary_not_active(query \\ from()) do
    where(
      query,
      [user: u],
      u.id not in subquery(Salary.by_active_salaries(true))
    )
  end

  @spec select_user_salary_attrs(queryable()) :: query()
  def select_user_salary_attrs(query) do
    select_merge(
      query,
      [user: u, salary: s],
      %{
        id: u.id,
        name: u.name,
        salary: %{
          amount: s.amount,
          active: s.active
        }
      }
    )
  end

  @spec maybe_filter_by_name(queryable(), map) :: query()
  def maybe_filter_by_name(query \\ from(), params)
  def maybe_filter_by_name(query, %{"filter" => %{"name" => name}}) do
    name = "%#{name}%"
    where(query, [user: u], ilike(u.name, ^name))
  end

  def maybe_filter_by_name(query, _params) do
    query
  end
end

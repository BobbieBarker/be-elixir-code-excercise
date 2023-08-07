defmodule BeExercise.Users.Salary do
  @moduledoc """
  This table is used to store user salary info. A user
  can only have one active salary at a time.
  """

  use BeExercise

  alias BeExercise.Users.User
  alias Constants.SalaryConstants

  @type t :: %__MODULE__{
    id: pos_integer() | nil,
    amount: map(),
    active: boolean(),
    user_id: pos_integer(),
    updated_at: DateTime.t() | nil,
    inserted_at: DateTime.t() | nil
  }

  @type query :: Ecto.Query.t()
  @type queryable :: Ecto.Queryable.t()

  @required [:user_id]
  @allowed [:active | @required]

  @enforce_keys @required

  @supported_currencies SalaryConstants.supported_currencies

  @derive {Jason.Encoder, only: [:amount, :active, :user_id, :inserted_at, :updated_at]}
  schema "user_salaries" do
    field :amount, Money.Ecto.Composite.Type
    field :active, :boolean, default: false

    belongs_to :user, User

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
    |> validate_and_cast_money(params, :amount)
    |> unique_constraint(
      :active,
      name: "user_salaries_active_user_true_id_index",
      message: "a user can only have one active salary at a time"
    )
  end

  # here I'm casting the params and adding it manually in the changeset
  # because Money will raise an argument error if we provide it an invalid currency.
  # Instead, what we're doing here allows us to detect unsupported currencies and return
  # a nice error inside of our ecto changeset.
  defp validate_and_cast_money(
    changeset,
    %{amount: %Money{} = money},
    field
  ) do
    put_change(changeset, field, money)
  end

  defp validate_and_cast_money(
    changeset,
    %{amount: %{amount: amount, currency: currency}},
    field
  ) do

    cond do
      amount < 0 ->
        add_error(changeset, field, "amount must be greater than zero")
      currency not in @supported_currencies ->
        add_error(changeset, field, "must use a supported currency")
      true ->
        amount
        |> Money.new(currency)
        |> then(&put_change(changeset, field, &1))
    end
  end

  defp validate_and_cast_money(
    changeset,
    _,
    _field
  ) do
    changeset
  end

  @doc false
  @spec from() :: query
  @spec from(queryable) :: query
  def from(query \\ __MODULE__), do: from(query, as: :salary)

  @doc false
  @spec by_active_salaries(queryable()) :: query()
  def by_active_salaries(query \\ from(), active) do
    query
    |> where([salary: s], s.active == ^active)
    |> select_user_id()
  end

  @spec select_user_id(queryable()) :: query()
  def select_user_id(query \\ from()) do
    select(query, [salary: s], s.user_id)
  end

  @spec order_by_last_updated_at(queryable()) :: query()
  def order_by_last_updated_at(query) do
    order_by(query, [user: u, salary: s], [desc: s.updated_at])
  end
end

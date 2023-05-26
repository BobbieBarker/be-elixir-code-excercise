defmodule BeExercise do
  @moduledoc """
  BeExercise keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  @type t_error() :: :ok | {:error, ErrorMessage.t()}
  @type t_res() :: :ok | {:error, Ecto.Changeset.t()}
  @type t_res(type) :: {:ok, type} | {:error, Ecto.Changeset.t()}
  @type t_error_res() :: t_res() | t_error()
  @type t_error_res(type) :: t_res(type) | ErrorMessage.t_res(type)

  @doc "When used, import Ecto."
  defmacro __using__(_opts) do
    quote do
      use Ecto.Schema
      @timestamps_opts type: :utc_datetime_usec

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
    end
  end
end

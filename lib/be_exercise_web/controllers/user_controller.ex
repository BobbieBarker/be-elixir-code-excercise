defmodule BeExerciseWeb.UserController do
  @moduledoc """
  This module contains route actions for user resources.
  """
  use BeExerciseWeb, :controller

  alias BeExercise.{Users, UserInvitationSupervisor}

  require Protocol

  Protocol.derive(Jason.Encoder, Money)

  @spec index(Plug.Conn.t, map()) :: Plug.Conn.t()
  def index(conn, params) do
    with users when is_list(users) <- Users.cached_find_recent_and_active_salaries(params) do
      json(conn, users)
    end
  end

  @spec invite_users(Plug.Conn.t, map()) :: Plug.Conn.t()
  def invite_users(conn, _params) do
    _task = send_user_invitations()

    send_resp(conn, :no_content, "")
  end
  # WIP this task supervisor might not be the right solution for a
  # high volume call.
  defp send_user_invitations() do
    Task.Supervisor.async_nolink(
      UserInvitationSupervisor,
      fn ->
        Users.all_active_users(%{})
        |> Task.async_stream(&Users.send_invite_email/1)
        |> Stream.run()
      end,
      [timeout: :timer.minutes(5)]
    )
  end
end

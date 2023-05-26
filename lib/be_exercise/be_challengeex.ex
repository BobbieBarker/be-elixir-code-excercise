defmodule BeExercise.BeChallengeex do
  @moduledoc """
  An adapter module to facilitate the mocking of the BEChallengex with mox.
  """

  defdelegate send_email(user), to: BEChallengex

  @callback send_email(map) :: {:ok, String.t} | {:error, any}
end

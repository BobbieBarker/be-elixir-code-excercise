defmodule BeExercise.Metrics do
  @moduledoc """
  Exposes an API for emitting telemetry events
  """

  def incr_invitation_success() do
    :telemetry.execute(
      [:be_exercise, :metrics, :users, :invitation_success],
      %{value: 1}
    )
  end

  def incr_invitation_failure() do
    :telemetry.execute(
      [:be_exercise, :metrics, :users, :invitation_failure],
      %{value: 1}
    )
  end
end

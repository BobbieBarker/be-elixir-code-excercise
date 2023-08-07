defmodule BeExercise.Config do
  @moduledoc false

  @app :be_exercise

  def be_challengeex do
    Application.get_env(@app, :be_challengeex, BeExercise.BeChallengeex)
  end
end

defmodule BeExercise.MixProject do
  use Mix.Project

  def project do
    [
      app: :be_exercise,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      dialyzer: [
        plt_add_apps: [:ex_unit, :mix],
        plt_local_path: ".check/local_plt",
        plt_core_path: ".check/core_plt",
        list_unused_filters: true,
        ignore_warnings: ".check/.dialyzer-ignore.exs",
        flags: [
          :no_opaque,
          :unknown,
          :unmatched_returns,
          :extra_return,
          :missing_return
        ]
      ],
      preferred_cli_env: [
        credo: :test,
        credo_diff: :test,
        dialyzer: :test,
        test: :test
      ],
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {BeExercise.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.7.2"},
      {:phoenix_ecto, "~> 4.4"},
      {:ecto_sql, "~> 3.6"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 3.3"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.18.16"},
      {:phoenix_live_dashboard, "~> 0.7.2"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.20"},
      {:jason, "~> 1.2"},
      {:plug_cowboy, "~> 2.5"},
      {:money, "~> 1.12"},
      {:be_challengex, github: "remotecom/be_challengex", tag: "0.0.1"},
      {:ecto_shorts, "~> 2.3"},
      {:error_message, "~> 0.3.1"},
      {:elixir_cache, "~> 0.3.1"},

      # test
      {:faker, "~> 0.17.0", only: [:dev, :test]},
      {:mox, "~> 1.0", only: [:test]},
      {:dialyxir, "~> 1.3", only: :test, runtime: false}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end

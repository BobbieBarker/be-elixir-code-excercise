defmodule BeExercise.SchemaCache.Repo.Redis do
  @moduledoc """
  PG Schema Cache redis adapter
  """

  use Cache,
    name: :repo_schema_redis_cache,
    adapter: Cache.Agent,
    opts: [],
    sandbox?: Mix.env() === :test
end

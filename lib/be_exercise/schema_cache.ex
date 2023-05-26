defmodule BeExercise.SchemaCache do
  @moduledoc """
  This module caches data queries under a key, so that we can
  make different queries with different TTLs
  """

  alias BeExercise.SchemaCache.{CacheKeyTransformer, Repo}
  alias BeExercise.SchemaCache

  require Logger

  defdelegate schema_cache_child(opts \\ []), to: SchemaCache.Repo.Redis, as: :child_spec

  @spec repo_redis_put(String.t, map, pos_integer | nil, map | struct) :: :ok | ErrorMessage.t
  def repo_redis_put(key, params, ttl \\ nil, value) do
    key
    |> CacheKeyTransformer.to_params_key(params)
    |> SchemaCache.Repo.Redis.put(ttl, value)
  end

  def repo_redis_get_or_fetch_by_params(key, params, ttl \\ nil, fnc) do
    get_or_fetch_by_params(Repo.Redis, key, params, ttl, fnc)
  end

  @spec repo_redis_invalidate_by_params(String.t, map) :: :ok | ErrorMessage.t
  def repo_redis_invalidate_by_params(key, params) do
    invalidate_by_params(Repo.Redis, key, params)
  end

  # Generic cache functions
  def get_or_fetch_by_params(cache, key, params, ttl \\ nil, fnc) do
    full_key = CacheKeyTransformer.to_params_key(key, params)

    case cache.get(full_key) do
      {:ok, nil} -> get_set_value(cache, full_key, ttl, fnc)
      {:ok, val} when is_list(val) -> val
      {:ok, val} -> {:ok, val}
      error -> fetch_from_database(fnc, error, cache)
    end
  end

  defp get_set_value(cache, full_key, ttl, fnc) do
    case fnc.() do
      {:ok, value} ->
        cache.put(full_key, ttl, value)
        {:ok, value}

      value when is_list(value) ->
        cache.put(full_key, ttl, value)
        value

      res ->
        res
    end
  end

  @spec invalidate_by_params(module, String.t(), map) :: :ok | ErrorMessage.t
  def invalidate_by_params(cache, key, params) do
    key
    |> CacheKeyTransformer.to_params_key(params)
    |> cache.delete()
    |> case do
      :ok ->
        :ok

      error ->
        Logger.error(
          "Could not invalidate by params in cache: #{inspect(cache)} error: #{inspect(error)}"
        )
    end
  end

  defp fetch_from_database(fnc, error, cache) do
    Logger.error(
      """
      Unable to fetch from cache
      Cache: #{inspect(cache)}
      Error: #{inspect(error)}
      Falling back to Source for data
      """
    )

    fnc.()
  end
end

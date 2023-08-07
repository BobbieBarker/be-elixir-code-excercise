defmodule BeExercise.SchemaCache.CacheKeyTransformer do
  def to_params_key(key, params) do
    "#{key}:#{Jason.encode!(params)}"
  end
end

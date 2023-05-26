defmodule BeExercise.SchemaCacheTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  alias BeExercise.SchemaCache

  defmodule TestCache do
    use Cache,
    name: :test_cache,
    adapter: Cache.Agent,
    sandbox?: Mix.env() === :test
  end

  defmodule FailCache do
    def get(_) do
      {:error, %Redix.ConnectionError{reason: :timeout}}
    end
  end

  setup do
    Cache.SandboxRegistry.start([TestCache])
    :ok
  end

  describe "&get_or_fetch_by_params/5" do
    test "runs function to put into cache if not existing" do
      key = build_key()
      params = %{test: build_key()}
      value = %{some_value: 243}

      res =
        SchemaCache.get_or_fetch_by_params(TestCache, key, params, fn ->
          {:ok, value}
        end)

      assert {:ok, value} === res
    end

    test "runs function to put into cache if not existing - list result" do
      key = build_key()
      params = %{test: build_key()}
      value = [:value]

      res =
        SchemaCache.get_or_fetch_by_params(TestCache, key, params, fn ->
          value
        end)

      assert value === res
    end

    test "fails to put into cache if function returns {:error, term}" do
      key = build_key()
      params = %{test: build_key()}
      error = build_key()

      assert {:error, error} ===
               SchemaCache.get_or_fetch_by_params(TestCache, key, params, fn ->
                 {:error, error}
               end)
    end

    test "fetches from cache instead of running function if already cached" do
      key = build_key()
      params = %{test: build_key()}
      value = %{some_value: 243}

      assert {:ok, ^value} =
               SchemaCache.get_or_fetch_by_params(TestCache, key, params, fn ->
                 {:ok, value}
               end)

      assert {:ok, value} ===
               SchemaCache.get_or_fetch_by_params(TestCache, key, params, fn ->
                 raise "Not Used"
               end)
    end

    test "fetches from cache instead of running function if already cached - list result" do
      key = build_key()
      params = %{test: build_key()}
      value = [:value]

      assert value ===
               SchemaCache.get_or_fetch_by_params(TestCache, key, params, fn ->
                 value
               end)

      assert value ===
               SchemaCache.get_or_fetch_by_params(TestCache, key, params, fn ->
                 raise "Not Used"
               end)
    end

    test "falls back to the database when cache returns an error" do
      key = build_key()
      params = %{test: build_key()}
      value = [:value]

      error =
        capture_log(fn ->
          assert value ===
                   SchemaCache.get_or_fetch_by_params(FailCache, key, params, fn ->
                     value
                   end)
        end)

      assert error =~ "Unable to fetch from cache"
    end
  end

  defp build_key do
    Base.encode32(:crypto.strong_rand_bytes(10))
  end
end

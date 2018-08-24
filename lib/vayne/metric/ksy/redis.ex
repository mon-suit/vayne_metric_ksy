defmodule Vayne.Metric.Ksy.Redis do

  @behaviour Vayne.Task.Metric

  alias Vayne.Metric.Ksy.Util

  #kcs.read_cmd kcs.write_cmd always get 404
  @metric ~w(
    kcs.connections kcs.cpu_load kcs.evicted_keys kcs.expired_keys kcs.hash_cmd
    kcs.hit_rate kcs.input_kbps kcs.list_cmd kcs.output_kbps kcs.qps
    kcs.set_cmd kcs.sort_cmd kcs.string_cmd kcs.total_keys kcs.usedmemory
  )

  @metric_KB ~w(kcs.input_kbps kcs.output_kbps)
  @metric_MB ~w(kcs.usedmemory)

  @doc """
  * `instanceId`: mongodb instanceId. Required.
  * `region`: db instance region. Required.
  * `secretId`: secretId for monitoring. Not required.
  * `secretKey`: secretKey for monitoring. Not required.
  """
  def init(params) do
    with {:ok, instanceId} <- Util.get_option(params, "instanceId"),
      {:ok, region} <- Util.get_option(params, "region"),
      {:ok, secret} <- Util.get_secret(params)
    do
      {:ok, {instanceId, region, secret}}
    else
      {:error, _} = e -> e
      error -> {:error, error}
    end
  end

  def run(stat, log_func) do
    metrics = Application.get_env(:vayne_metric_ksy, :redis_metric, @metric)
    ret = Util.request_metric("KCS", metrics, stat, log_func, {@metric_KB, @metric_MB})
    {:ok, ret}
  end

  def clean(_), do: :ok

end

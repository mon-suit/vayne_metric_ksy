defmodule Vayne.Metric.Ksy.Krds do

  @behaviour Vayne.Task.Metric

  alias Vayne.Metric.Ksy.Util

  @metric ~w(
    rds.bytes_received rds.bytes_sent rds.com_delete rds.com_insert rds.com_replace
    rds.com_select rds.com_update rds.connection_used_percent rds.created_tmp_disk_tables
    rds.innodb_buffer_pool_hit_ratio rds.innodb_data_fsyncs rds.innodb_data_reads
    rds.innodb_data_writes rds.max_connections rds.max_used_connections
    rds.myisam_keycache_readhit_ration rds.myisam_keycache_used_percent
    rds.myisam_keycache_writehit_ration rds.qcache_hit_ratio rds.qcache_used_percent
    rds.qps rds.rbps rds.resident_memory_size rds.riops rds.select_scan rds.slave_delay
    rds.slow_queries rds.space_used_percent rds.table_locks_waited rds.threads_connected
    rds.threads_running rds.tps rds.wbps rds.wiops
  )

  @metric_KB ~w(rds.bytes_received rds.bytes_sent)
  @metric_MB ~w(rds.resident_memory_size)

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
    metrics = Application.get_env(:vayne_metric_ksy, :krds_metric, @metric)
    ret = Util.request_metric("KRDS", metrics, stat, log_func, {@metric_KB, @metric_MB})
    {:ok, ret}
  end

  def clean(_), do: :ok

end

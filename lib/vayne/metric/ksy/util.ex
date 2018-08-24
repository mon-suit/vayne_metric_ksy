defmodule Vayne.Metric.Ksy.Util do

  def request_metric(namespace, metrics, {instanceId, region, secret}, log_func, {metric_kB, metric_mB}) do
    Enum.reduce(metrics, %{}, fn (metric, acc) ->
      now = :os.system_time(:seconds)
      resp = namespace
      |> make_url(now, metric, {instanceId, region, secret})
      |> request_url()
      case resp do
        {:ok, nil} ->
          log_func.("get empty value. instance: #{instanceId}, metric: #{metric}")
          acc
        {:error, error} ->
          log_func.("get instance: #{instanceId}, metric: #{metric} error: #{inspect error}")
          acc
        {:ok, value} ->
          value = if metric in metric_kB, do: value * 1024, else: value
          value = if metric in metric_mB, do: value * 1024 * 1024, else: value
          Map.put(acc, metric, value)
      end
    end)
  end

  def get_option(params, key) do
    case Map.fetch(params, key) do
      {:ok, _} = v -> v
      _ -> {:error, "#{key} is missing"}
    end
  end

  def get_secret(params) do

    env_secretId = Application.get_env(:vayne_metric_ksy, :secretId)
    env_secretKey = Application.get_env(:vayne_metric_ksy, :secretKey)

    cond do
      Enum.all?(~w(secretId secretKey), &(Map.has_key?(params, &1))) ->
        {:ok, {params["secretId"], params["secretKey"]}}
      Enum.all?([env_secretId, env_secretKey], &(not is_nil(&1))) ->
        {:ok, {env_secretId, env_secretKey}}
      true ->
        {:error, "secretId or secretKey is missing"}
    end
  end

  @before_minutes -3
  def make_url(namespace, now, metric, {instanceId, region, {secretId, secretKey}}) do
    time      = now  |> Timex.from_unix
    startTime = time |> Timex.shift(minutes: @before_minutes) |> Timex.format!("{ISO:Extended:Z}")
    endTime   = time |> Timex.format!("{ISO:Extended:Z}")

    url = "http://monitor.domain.api.ksyun.com/"
      <> "?Action=GetMetricStatistics"
      <> "&Version=2010-05-25"
      <> "&InstanceID=#{instanceId}"
      <> "&Namespace=#{namespace}"
      <> "&MetricName=#{metric}"
      <> "&StartTime=#{startTime}"
      <> "&EndTime=#{endTime}"
      <> "&Aggregate=Average,Sum,Count,Max,Min"
      <> "&Period=60"

    AWSAuth.sign_url(secretId, secretKey, "GET", url, region, "monitor")
  end

  def request_url(url) do
    response = HTTPotion.get(url, timeout: :timer.seconds(10))
    #{:ok, worker_pid} = HTTPotion.spawn_worker_process(url)
    #response = HTTPotion.get(url, timeout: :timer.seconds(20), direct: worker_pid)
    case response do
      %{status_code: 200, body: body} ->
        point = body |> parse_resp |> List.last
        {:ok, point[:Max]}
      %{status_code: code} ->
        {:error, "status code #{code}"}
      error ->
        {:error, error}
    end
  end

  def parse_resp(res) do
    import SweetXml
    res |> xpath(
      ~x"//GetMetricStatisticsResponse/GetMetricStatisticsResult/Datapoints/member"l,
      Average:     ~x"./Average/text()"Fo,
      Max:         ~x"./Max/text()"Fo,
      Min:         ~x"./Min/text()"Fo,
      SampleCount: ~x"./SampleCount/text()"Io,
      Sum:         ~x"./Sum/text()"Io,
      Timestamp:   ~x"./Timestamp/text()"s
    )
  end

end

defmodule HostCore.Claims.Server do
  require Logger
  use Gnat.Server

  # Topic wasmbus.rpc.{prefix}.claims.put, .get
  # claims fields: call_alias, issuer, name, revision, tags, version, public_key

  def request(%{topic: topic, body: body}) do
    cmd = topic |> String.split(".") |> Enum.at(4)
    Logger.info("Received claims command (#{cmd})")
    # PUT
    if cmd == "get" do
      # Subscription failure
    else
      claims = Msgpax.unpack!(body) |> Map.new(fn {k, v} -> {String.to_atom(k), v} end)
      # Note the name difference here, outside of OTP the claims use JWT naming conventions
      key = claims.sub
      :ets.insert(:claims_table, {key, claims})

      if claims.call_alias != nil && String.length(claims.call_alias) > 1 do
        :ets.insert(:callalias_table, {claims.call_alias, claims.sub})
      end

      :ok
    end
  end
end

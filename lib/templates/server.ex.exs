# Automatically generated by twirp_elixir, do not edit manually.
defmodule <%= prefix %>.RPC.Server do
  @moduledoc false

  use Plug.Router
  plug(Plug.Logger)
  plug(:match)
  plug(:dispatch, builder_opts())

  post "/twirp/:service_name/:rpc_name" do
    pb_mod = opts[:pb_mod]
    handler = opts[:handler]
    {service_name, rpc_name} = pb_mod.fqbins_to_service_and_rpc_name(service_name, rpc_name)
    rpc = pb_mod.find_rpc_def(service_name, rpc_name)
    {:ok, body, conn} = Plug.Conn.read_body(conn)

    case get_req_header(conn, "content-type") do
      ["application/json"] ->
        request = Jason.decode!(body)
        request = pb_mod.from_json(request, rpc.input)
        function = :"handle_#{Macro.underscore(Atom.to_string(rpc_name))}"
        result = apply(handler, function, [request])
        response_json = pb_mod.to_json(result, rpc.output)
        response = Jason.encode_to_iodata!(response_json)

        conn
        |> put_resp_header("content-type", "application/json")
        |> send_resp(200, response)

      ["application/protobuf"] ->
        request = pb_mod.decode_msg(body, rpc.input)
        function = :"handle_#{Macro.underscore(Atom.to_string(rpc_name))}"
        result = apply(handler, function, [request])
        response_pb = pb_mod.encode_msg(result, rpc.output)

        conn
        |> put_resp_header("content-type", "application/protobuf")
        |> send_resp(200, response_pb)
    end
  end

  match _ do
    send_resp(conn, 404, "oops")
  end

  def start_link(options) do
    children = [
      child_spec(options)
    ]

    http_options = Keyword.drop(options, [:pb_mod, :handler])

    message =
      "Starting #{inspect(__MODULE__)} for #{inspect(options[:handler])} with #{inspect(http_options)}"

    require Logger
    Logger.info(message)

    Supervisor.start_link(children, strategy: :one_for_one, name: TwirpServer.Supervisor)
  end

  def child_spec(options) do
    options = Keyword.put_new(options, :port, 8080)
    {scheme, options} = Keyword.pop(options, :scheme, :http)
    {handler, options} = Keyword.pop(options, :handler)
    {pb_mod, options} = Keyword.pop(options, :pb_mod)
    plug = {__MODULE__, [handler: handler, pb_mod: pb_mod]}
    Plug.Cowboy.child_spec(scheme: scheme, plug: plug, options: options)
  end
end

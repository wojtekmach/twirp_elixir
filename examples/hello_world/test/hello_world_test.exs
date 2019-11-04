defmodule HelloWorldTest do
  use ExUnit.Case, async: true
  alias HelloWorld.RPC.HelloWorldClient

  test "protobuf" do
    client = HelloWorldClient.new(base_url: "http://localhost:8080")
    assert HelloWorldClient.hello(client, %{name: "World"}) == %{message: "Hello World!"}
  end

  test "json" do
    assert post!(
             "http://localhost:8080/twirp/example.hello_world.HelloWorld/Hello",
             ~s({"name": "World"}),
             [{"content-type", "application/json"}]
           ) == ~s({"message":"Hello World!"})
  end

  defp post!(url, data, headers) do
    options = []
    {:ok, _status, _headers, ref} = :hackney.request(:post, url, headers, data, options)
    {:ok, body} = :hackney.body(ref)
    body
  end
end

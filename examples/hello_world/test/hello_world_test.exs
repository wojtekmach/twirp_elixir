defmodule Handler do
  def handle_hello(%{name: name}) do
    %{message: "Hello #{name}!"}
  end
end

defmodule HelloWorldTest do
  use ExUnit.Case, async: true

  test "protobuf" do
    {:ok, _} = start_supervised({HelloWorld.RPC.HelloWorldServer, handler: Handler, port: 8080})

    assert HelloWorld.RPC.HelloWorldClient.hello("http://localhost:8080/twirp", %{name: "World"}) ==
             %{message: "Hello World!"}
  end

  test "json" do
    {:ok, _} = start_supervised({HelloWorld.RPC.HelloWorldServer, handler: Handler, port: 8081})

    assert HTTPoison.post!(
             "http://localhost:8081/twirp/example.hello_world.HelloWorld/Hello",
             ~s({"name": "World"}),
             [{"content-type", "application/json"}]
           ).body == ~s({"message":"Hello World!"})
  end
end

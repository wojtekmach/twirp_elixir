defmodule Handler do
  def handle_Hello(%{name: name}) do
    %{message: "Hello #{name}"}
  end
end

defmodule HelloWorldTest do
  use ExUnit.Case, async: true

  test "hello world" do
    HelloWorld.RPC.HelloWorldServer.start_link(handler: Handler, port: 8080)

    assert HelloWorld.RPC.HelloWorldClient.hello("http://localhost:8080/twirp", %{name: "World"}) ==
             %{message: "Hello World"}
  end
end

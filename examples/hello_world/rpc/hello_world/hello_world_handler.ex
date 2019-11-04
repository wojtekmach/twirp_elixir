defmodule HelloWorld.RPC.HelloWorldHandler do
  def handle_hello(%{name: name}) do
    %{message: "Hello #{name}!"}
  end
end

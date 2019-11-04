# Twirp

**Work in progress**

Twirp implementation in Elixir.

## Links

* [Twirp: a sweet new RPC framework for Go](https://blog.twitch.tv/twirp-a-sweet-new-rpc-framework-for-go-5f2febbf35f)
* [Twirp documentation](https://twitchtv.github.io/twirp/docs/intro.html)
* [TwirpElixir example app](https://github.com/wojtekmach/twirp_elixir/tree/master/examples/hello_world)
* Screencast:

  [![asciicast](https://asciinema.org/a/8rvBfbRZvFxWcyt2RI9vAnPng.png)](https://asciinema.org/a/8rvBfbRZvFxWcyt2RI9vAnPng)

## Usage

Create a new Mix project:

```
mix new hello_world --sup
```

Use Twirp:

```elixir
# mix.exs
defp deps() do
  {:twirp_elixir, github: "wojtekmach/twirp_elixir"},
  {:plug_cowboy, "~> 2.0"},
  {:json, "~> 1.0"},
  {:hackney, "~> 1.15"}
end
```

The generated Twirp modules (more on the below) don't have a runtime dependency on Twirp so you
may choose not to depend on it in prod by setting `{:twirp_elixir, github: "wojtekmach/twirp_elixir", only: [:dev, :test]}`.
However, they do have runtime dependnecy on Plug.Cowboy, Jason, and Hackney so these packages need
to be included in your `mix.exs`.

Next, install Twirp compiler.

```elixir
# mix.exs
def project() do
  # ...
  compilers: compilers(Mix.env()),
  elixirc_paths: ["lib", "rpc"],
  erlc_paths: ["src", "rpc"]
end

defp compilers(:dev), do: [:twirp | Mix.compilers()]
defp compilers(:test), do: [:twirp | Mix.compilers()]
defp compilers(_), do: Mix.compilers()
```

Note, this compiler is used to generate Elixir and Erlang _source files_ (which will be compiled by
the standard compilers) and so you don't need to include it in prod.

Next, create an RPC definition for your service:

```
# rpc/hello_world/hello_world.proto
syntax = "proto3";
package example.hello_world;

service HelloWorld {
    rpc Hello(HelloRequest) returns (HelloResponse);
}

message HelloRequest {
    string name = 1;
}

message HelloResponse {
    string message = 1;
}
```

After running `mix compile` you should see generated client & server module files in the `rpc/`
directory.

Now, create a handler module, this is where we put the business logic of handling a particular RPC
call:

```elixir
defmodule HelloWorld.RPC.HelloWorldHandler do
  def handle_hello(%{name: name}) do
    %{message: "Hello #{name}!"}
  end
end
```

Note, the `handle_hello` function corresponds to the `Hello` rpc in the service definition.

Finally, add the server to your application's supervision tree:

```elixir
# lib/hello_world/application.ex
def start(_type, _args) do
  children = [
    {HelloWorld.RPC.HelloWorldServer, handler: Hello.RPC.HelloWorldHandler, port: 8080}
  ]

  opts = [strategy: :one_for_one, name: HelloWorld.Supervisor]
  Supervisor.start_link(children, opts)
end
```

Since Twirp automatically generates a client for your service we can use it to test it.
And because we've installed the generated server in the supervision tree, it will be booted when
we start an IEx session:

```
iex -S mix
```

```elixir
iex> client = HelloWorld.RPC.HelloWorldClient.new(base_url: "http://localhost:8080")
iex> client |> HelloWorld.RPC.HelloWorldClient.hello(%{name: "world"})
# 13:44:40.958 [info]  POST /twirp/example.hello_world.HelloWorld/Hello
# 13:44:40.965 [info]  Sent 200 in 6ms
%{message: "Hello world!"}
```

See [`examples/hello_world`](examples/hello_world) for full source code of the example app.

## License

Copyright (c) 2019 Plataformatec

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at [http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

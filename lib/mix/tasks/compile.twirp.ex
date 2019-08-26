defmodule Mix.Tasks.Compile.Twirp do
  use Mix.Task.Compiler

  @impl true
  def run(_) do
    protos = Path.wildcard("rpc/**/*.proto")
    prefix = Mix.Project.config()[:app] |> Atom.to_string() |> Macro.camelize()
    generate_pb_modules(protos)

    template_root = Path.expand("../../templates", __DIR__)

    code = EEx.eval_file(Path.join(template_root, "client.ex.exs"), prefix: prefix)
    write!("rpc/client.ex", code)

    code = EEx.eval_file(Path.join(template_root, "server.ex.exs"), prefix: prefix)
    write!("rpc/server.ex", code)

    for proto <- protos do
      name = proto |> Path.basename() |> Path.rootname()
      service_root = Path.dirname(proto)
      source = String.to_charlist(Path.join(service_root, "#{name}_pb.erl"))
      {:ok, pb_mod, binary} = :compile.file(source, [:binary, :report])
      :code.purge(pb_mod)
      {:module, pb_mod} = :code.load_binary(pb_mod, source, binary)

      for service_name <- pb_mod.get_service_names() do
        template_root = Path.expand("../../templates", __DIR__)

        bindings = [prefix: prefix, pb_mod: pb_mod, service_name: service_name]
        code = EEx.eval_file(Path.join(template_root, "service_client.ex.exs"), bindings)
        write!(Path.join(service_root, "#{name}_client.ex"), code)

        code = EEx.eval_file(Path.join(template_root, "service_server.ex.exs"), bindings)
        write!(Path.join(service_root, "#{name}_server.ex"), code)
      end
    end

    :ok
  end

  defp generate_pb_modules(protos) do
    protoc_erl_path = Path.join([Mix.Project.deps_paths()[:gpb], "bin", "protoc-erl"])

    args =
      [
        protoc_erl_path,
        "-modsuffix",
        "_pb",
        "-json",
        "-maps",
        "-strbin"
      ] ++ protos

    System.cmd("escript", args, into: IO.stream(:stdio, :line))
  end

  defp write!(path, code) do
    File.write!(path, Code.format_string!(code))
  end

  @impl true
  def clean() do
    Path.wildcard("rpc/**/*.{erl,ex}")
    |> Enum.each(&File.rm_rf!/1)
  end
end

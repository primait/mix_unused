defmodule MixUnused.Analyzers.Calls do
  @moduledoc false

  alias MixUnused.Debug
  alias MixUnused.Exports
  alias MixUnused.Meta
  alias MixUnused.Tracer

  @type t :: Graph.t()

  @doc """
  Creates a graph where each node is a function and an edge from `f` to `g`
  means that the function `f` calls `g`.
  """
  @spec calls_graph(Tracer.data(), Exports.t()) :: t()
  def calls_graph(data, exports) do
    Graph.new(type: :directed)
    |> add_calls(data)
    |> add_calls_from_default_functions(exports)
    |> Debug.debug(&log_graph/1)
  end

  defp add_calls(graph, data) do
    for {m, calls} <- data,
        {mfa, %{caller: {f, a}}} <- calls,
        reduce: graph do
      acc -> Graph.add_edge(acc, {m, f, a}, mfa)
    end
  end

  defp add_calls_from_default_functions(graph, exports) do
    # A function with default arguments is splitted at compile-time in multiple functions
    #  with different arities.
    #  The main function is indirectly called when a function with default arguments is called,
    #  so the graph should contain an edge for each generated function (from the generated
    #  function to the main one).
    for {{m, f, a} = mfa, %Meta{doc_meta: meta}} <- exports,
        defaults = Map.get(meta, :defaults, 0),
        defaults > 0,
        arity <- (a - defaults)..(a - 1),
        reduce: graph do
      graph -> Graph.add_edge(graph, {m, f, arity}, mfa)
    end
  end

  @doc """
  Gets all the exported functions called from some module at compile-time.
  """
  @spec called_at_compile_time(Tracer.data(), Exports.t()) :: [mfa()]
  def called_at_compile_time(data, exports) do
    for {_m, calls} <- data,
        {mfa, %{caller: nil}} <- calls,
        Map.has_key?(exports, mfa),
        into: MapSet.new(),
        do: mfa
  end

  defp log_graph(graph) do
    write_edgelist(graph)
    write_binary(graph)
  end

  defp write_edgelist(graph) do
    {:ok, content} = Graph.to_edgelist(graph)
    path = Path.join(Mix.Project.manifest_path(), "graph.txt")
    File.write!(path, content)

    Mix.shell().info([
      IO.ANSI.yellow_background(),
      "Serialized edgelist to #{path}",
      :reset
    ])
  end

  defp write_binary(graph) do
    content = :erlang.term_to_binary(graph)
    path = Path.join(Mix.Project.manifest_path(), "graph.bin")
    File.write!(path, content)

    Mix.shell().info([
      IO.ANSI.yellow_background(),
      "Serialized graph to #{path}",
      IO.ANSI.reset(),
      IO.ANSI.light_black(),
      "\n\nTo use it from iex:\n",
      ~s{
        Mix.install([libgraph: ">= 0.0.0"])
        graph = "#{path}" |> File.read!() |> :erlang.binary_to_term()
        Graph.info(graph)
      },
      IO.ANSI.reset()
    ])
  end
end

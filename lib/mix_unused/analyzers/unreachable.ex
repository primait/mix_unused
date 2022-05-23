defmodule MixUnused.Analyzers.Unreachable do
  @moduledoc """
  Finds all the reachable exported functions starting from a set of well-known used functions.
  All remaining functions are considered "unused".
  """

  alias MixUnused.Analyzers.Calls
  alias MixUnused.Analyzers.Unreachable.Config
  alias MixUnused.Analyzers.Unreachable.Usages
  alias MixUnused.Meta

  @behaviour MixUnused.Analyze

  defmodule RootChecker do
    @type t :: %__MODULE__{
            roots: list(mfa()),
            vertices: list(mfa()),
            root_only: boolean()
          }

    defstruct roots: [], vertices: [], root_only: false

    @spec new(Graph.t(), boolean()) :: RootChecker.t()
    def new(graph, true) do
      vertices = graph |> Graph.vertices() |> MapSet.new()

      roots =
        vertices
        |> Enum.filter(&(Graph.in_degree(graph, &1) == 0))
        |> MapSet.new()

      %__MODULE__{vertices: vertices, roots: roots, root_only: true}
    end

    def new(_graph, false), do: %__MODULE__{}

    # if the root_only flag is set, check if the call is a root or if its never called at all (out of the call graph)
    @spec isRoot?(RootChecker.t(), mfa()) :: boolean
    def isRoot?(
          %__MODULE__{roots: roots, vertices: vertices, root_only: root_only},
          mfa
        ) do
      not root_only or mfa in roots or mfa not in vertices
    end
  end

  @impl true
  def message, do: "is unreachable"

  @impl true
  def analyze(data, exports, config) do
    config = Config.cast(config)
    graph = Calls.calls_graph(data, exports)
    usages = Usages.usages(config, exports)
    reachables = graph |> Graph.reachable(usages) |> MapSet.new()
    called_at_compile_time = Calls.called_at_compile_time(data, exports)

    root_checker = RootChecker.new(graph, config.root_only)

    for {mfa, _meta} = call <- exports,
        candidate?(call),
        mfa not in usages,
        mfa not in reachables,
        mfa not in called_at_compile_time,
        RootChecker.isRoot?(root_checker, mfa),
        into: %{},
        do: call
  end

  # Clause to detect an unused struct (it is generated)
  defp candidate?({{_f, :__struct__, _a}, _meta}), do: true
  # Clause to ignore all generated functions
  defp candidate?({_mfa, %Meta{generated: true}}), do: false
  defp candidate?(_), do: true
end

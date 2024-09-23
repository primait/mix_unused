defmodule MixUnused.Exports do
  @moduledoc """
  Detects the functions exported by the application.
  In Elixir slang, an "exported" function is called "public" function.
  """

  alias MixUnused.Meta

  @type t() :: %{mfa() => Meta.t()}

  @spec application(atom(), Config.t()) :: t()
  def application(name, config) do
    _ = Application.load(name)

    name
    |> Application.spec(:modules)
    |> Enum.flat_map(&config.fetcher.fetch/1)
    |> Map.new()
  end
end

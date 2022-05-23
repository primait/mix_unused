defmodule MixUnused.Analyzers.Unreachable.Config do
  @moduledoc false

  alias __MODULE__, as: Config

  @type t :: %Config{
          usages: [module() | mfa()],
          usages_discovery: [module()],
          root_only: boolean()
        }

  defstruct usages: [],
            usages_discovery: [],
            root_only: true

  @spec cast(Enum.t()) :: Config.t()
  def cast(map) do
    struct!(Config, map)
  end
end

defmodule MixUnused.Meta do
  @moduledoc """
  Metadata of the functions
  """

  @typedoc """
  Struct describing function metadata.

  - `:signature` - stringified representation of the function call. Used for display purposes.
  - `:file` - path to the file that contains definition of given function.
  - `:line` - integer line number where the function is located within file
    (currently, it can point to the line where documentation is defined, not
    exactly to function head).
  - `:doc_meta` - documentation metadata of the given function.
  - `:extra` - additional metadata that can be used by the analyzers.
  """
  @type t() :: %__MODULE__{
          signature: String.t(),
          file: String.t(),
          line: non_neg_integer(),
          doc_meta: map(),
          extra: map(),
        }

  defstruct signature: nil,
            file: "nofile",
            line: 1,
            doc_meta: %{},
            extra: %{}
end

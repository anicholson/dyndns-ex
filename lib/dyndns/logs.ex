defmodule Logs do
  @moduledoc """
  Utility functions that wrap logger calls in a module context.
  """
  defmacro __using__(_) do
    quote do
      import Logs
      require Logger
    end
  end

  @doc """
  Returns the name of the module that called the macro.
  If the module has implemented a `@module` attribute, then that value will be returned instead.
  """
  defmacro module_name() do
    fallback = __CALLER__.module |> to_string

    quote do
      case @module do
        name -> name
        _ -> unquote(fallback)
      end
    end
  end

  defmacro debug(msg) do
    quote do
      Logger.debug("[#{module_name()}]: #{unquote(msg)}")
    end
  end

  defmacro info(msg) do
    quote do
      Logger.info("[#{module_name()}]: #{unquote(msg)}")
    end
  end

  defmacro warn(msg) do
    quote do
      Logger.warn("[#{module_name()}]: #{unquote(msg)}")
    end
  end

  defmacro error(msg) do
    quote do
      Logger.error("[#{module_name()}]: #{unquote(msg)}")
    end
  end
end

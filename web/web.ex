defmodule Ppa.Web do
  @moduledoc """
  A module that keeps using definitions for controllers,
  views and so on.

  This can be used in your application as:

      use Ppa.Web, :controller
      use Ppa.Web, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below.
  """

  def model do
    quote do
      use Ecto.Schema

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
    end
  end

  def controller do
    quote do
      use Phoenix.Controller

      alias Ppa.Repo
      import Ecto
      import Ecto.Query

      import Ppa.Router.Helpers
      import Ppa.Gettext
    end
  end

  def view do
    quote do
      use Phoenix.View, root: "web/templates"

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_csrf_token: 0, get_flash: 2, view_module: 1]

      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML
      use Number
      import Ppa.Router.Helpers
      import Ppa.ErrorHelpers
      import Ppa.Gettext
      import Ppa.Web.View.ComponentHelpers

    end
  end

  def router do
    quote do
      use Phoenix.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel

      alias Ppa.Repo
      import Ecto
      import Ecto.Query
      import Ppa.Gettext

      def handle_info({_pid, _payload}, state),
        do: {:noreply, state}

      def handle_info({:DOWN, _ref, :process, _pid, :normal}, state),
        do: {:noreply, state}

    end
  end

  def channel_ex do
    quote do
      use Phoenix.Channel

      alias Ppa.Repo
      import Ecto
      import Ecto.Query
      import Ppa.Gettext
      require Logger

      def handle_info({_pid, _payload}, state),
        do: {:noreply, state}

      def handle_info({:DOWN, _ref, :process, _pid, :normal}, state),
        do: {:noreply, state}

      def handle_in(action, params, socket) do
        try do
          exec_handle_in(action, params, socket)
        rescue
          e in ErlangError -> Rollbax.report(:error, e, System.stacktrace())
               Logger.error("#{inspect e} STACK: #{inspect System.stacktrace()}")
               {:stop, e, :exception, socket}
          e -> Rollbax.report(:error, e, System.stacktrace())
               Logger.error("#{inspect e} STACK: #{inspect System.stacktrace()}")
               {:stop, e, :exception, socket}
        end
      end
    end
  end

  def handler do
    quote do
      import Phoenix.Socket, only: [assign: 3]

      alias Ppa.Repo
      import Ecto
      import Ecto.Query, only: [from: 1, from: 2]
      import Ppa.Gettext
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end

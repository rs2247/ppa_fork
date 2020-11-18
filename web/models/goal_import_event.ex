defmodule Ppa.GoalImportEvent do
  use Ppa.Web, :model
  require Logger

  schema "goal_import_events" do
    field :admin_user_id, :integer
    field :import_file, :string
    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, ~w(admin_user_id import_file))
  end

  def new_changeset(params) do
    changeset(%__MODULE__{}, params)
  end
end

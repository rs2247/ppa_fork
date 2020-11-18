defmodule Ppa.CustomValue do
  use Ppa.Web, :model
  require Logger
  
  schema "custom_values" do
    field :customized_type , :string
    field :customized_id   , :integer
    field :custom_field_id , :integer
    field :value           , :string
  end
end

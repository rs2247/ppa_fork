defmodule Ppa.Util.Analisys.Base do
  require Logger

  @ppt_shared_path Application.get_env(:ppa, :ppt_generator)[:shared]
  @ppt_templates_path Application.get_env(:ppa, :ppt_generator)[:templates]

  def generate_presentation(input_map, template) do
    parameters_filename = "char_#{Ecto.UUID.generate}.json"
    file_path = "/shared/#{parameters_filename}"
    File.write file_path, Poison.encode!(input_map), [:binary]

    # { output, _ } = System.cmd("docker", ["run", "-v", "/data/presentation_generator:/app", "-v", "#{@ppt_shared_path}:/shared", "-v", "#{@ppt_templates_path}:/templates", "ppt_generator", "ruby", "template_processor.rb", template, parameters_filename])
    { output, _ } = System.cmd("docker", ["run", "-v", "#{@ppt_shared_path}:/shared", "-v", "#{@ppt_templates_path}:/templates", "ppt_generator", "ruby", "template_processor.rb", template, parameters_filename])

    :file.delete(file_path)
    output
  end
end

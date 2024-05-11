# frozen_string_literal: true

class Favicon < Nanoc::Filter
  identifier :favicon
  type       :binary

  def run(filename, params = {})
    # we might use params to define which size to generate, currently hardcoded to 16 & 32px
    system(
      # the convert command expects a filename ending with .ico, mv it to nanoc expected filename then
      "convert #{filename} -define icon:auto-resize=16,32 #{output_filename}.ico && mv #{output_filename}.ico #{output_filename}"
    )
  end
end

# frozen_string_literal: true

class Thumbnailize < Nanoc::Filter
  identifier :thumbnailize
  type       :binary

  def run(filename, params = {})
    system(
      'magick',
      filename,
      '-resize',
      params[:width].to_s,
      '-strip',
      '-interlace',
      'Plane',
      '-quality',
      @config[:cover][:quality],
      output_filename
    )
  end
end

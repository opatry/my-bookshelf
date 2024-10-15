# frozen_string_literal: true

require 'fileutils'

class Thumbnailize < Nanoc::Filter
  identifier :thumbnailize
  type       :binary

  def run(filename, params = {})
    output_dir = File.dirname(output_filename)
    FileUtils.mkdir_p(output_dir) unless Dir.exist?(output_dir)
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

# frozen_string_literal: true

require 'fileutils'

class Thumbnailize < Nanoc::Filter
  identifier :thumbnailize
  type       :binary

  def run(filename, params = {})
    puts "output_dir1=#{output_dir} -> #{Dir.exist?(output_dir)}"
    output_dir = File.dirname(output_filename)
    FileUtils.mkdir_p(output_dir) unless Dir.exist?(output_dir)
    puts "filename=#{filename} -> #{output_filename}"
    puts "output_dir2=#{output_dir} -> #{Dir.exist?(output_dir)}"
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

# frozen_string_literal: true

require 'htmlcompressor'

class HtmlCompressorFilter < Nanoc::Filter
  identifier :html_compressor

  def run(content, params = {})
    # can't delete filter params, being immutable/frozen, need to copy before
    params2 = params.dup
    type = params2.delete(:type)
    case type
    when 'txt'
      # do nothing
      content
    else
      HtmlCompressor::Compressor.new(params2).compress(content)
    end
  end
end

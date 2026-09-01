require "image_processing/mini_magick"

# Normalizes a just-uploaded book cover before it is stored: resizes it down to
# at most 575px wide (matching the static site's script/tools/normalize_images.sh)
# while preserving aspect ratio and the original format, filename and content type.
#
# Returns an ActionDispatch::Http::UploadedFile (same interface as a raw form
# upload), so the controller can keep passing it straight into book_params.
class CoverProcessor
  MAX_WIDTH = 575

  def self.call(uploaded)
    return uploaded if uploaded.blank?

    new(uploaded).call
  end

  def initialize(uploaded)
    @uploaded = uploaded
  end

  def call
    processed = ImageProcessing::MiniMagick
                .source(@uploaded)
                .resize_to_limit(MAX_WIDTH, nil)
                .call

    ActionDispatch::Http::UploadedFile.new(
      tempfile: processed,
      filename: @uploaded.original_filename,
      type: @uploaded.content_type
    )
  end
end

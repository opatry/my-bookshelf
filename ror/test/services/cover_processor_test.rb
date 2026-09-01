require "test_helper"

class CoverProcessorTest < ActiveSupport::TestCase
  def uploaded_fixture(name, content_type)
    ActionDispatch::Http::UploadedFile.new(
      tempfile: File.open(Rails.root.join("test/fixtures/files", name)),
      filename: File.basename(name),
      type: content_type
    )
  end

  test "returns the input untouched when blank" do
    assert_nil CoverProcessor.call(nil)
  end

  test "resizes a wide image down to the target width" do
    processed = CoverProcessor.call(uploaded_fixture("cover_wide.jpg", "image/jpeg"))

    image = MiniMagick::Image.read(processed.tempfile)
    assert_operator image.width, :<=, CoverProcessor::MAX_WIDTH
    assert_equal "cover_wide.jpg", processed.original_filename
    assert_equal "image/jpeg", processed.content_type
  end

  test "leaves a small image untouched in dimensions" do
    processed = CoverProcessor.call(uploaded_fixture("cover.jpg", "image/jpeg"))

    image = MiniMagick::Image.read(processed.tempfile)
    assert_equal 60, image.width
  end
end

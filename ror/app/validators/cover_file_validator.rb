# Validates an attached cover file: allowed content types and a maximum size,
# applied to keep storage/payloads reasonable before any resizing happens.
class CoverFileValidator < ActiveModel::EachValidator
  ALLOWED_TYPES = %w[image/jpeg image/png image/webp].freeze
  MAX_BYTES = 3.megabytes

  def validate_each(record, attribute, value)
    return unless value.attached?

    unless ALLOWED_TYPES.include?(value.content_type)
      record.errors.add(attribute, :invalid_content_type)
    end

    if value.byte_size > MAX_BYTES
      record.errors.add(attribute, :too_large, max_megabytes: MAX_BYTES / 1.megabyte)
    end
  end
end

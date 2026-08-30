class Isbn13Validator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?
    return if Isbn13.valid?(value)

    record.errors.add(attribute, :invalid_isbn)
  end
end

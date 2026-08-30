# Applies French typography/sanitization to the given attributes before saving.
#
#   class Book < ApplicationRecord
#     include Sanitizable
#     sanitizes :title, :author, :description
#   end
module Sanitizable
  extend ActiveSupport::Concern

  class_methods do
    def sanitizes(*attributes)
      before_validation do
        attributes.each do |attribute|
          raw = public_send(attribute)
          next if raw.blank?

          public_send("#{attribute}=", FrenchTypography.sanitize(raw))
        end
      end
    end
  end
end

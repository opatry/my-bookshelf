module Admin
  class BaseController < ApplicationController
    layout "admin"
    helper AdminHelper

    before_action :require_default_owner

    private

    def default_owner
      @default_owner ||= User.default_owner
    end

    # Phase 1 has no authentication: admin acts on the seeded default user.
    def require_default_owner
      return if default_owner

      raise ActiveRecord::RecordNotFound, "Default user missing — run bin/rails db:seed"
    end
  end
end

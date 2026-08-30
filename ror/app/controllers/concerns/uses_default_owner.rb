# Resolves the "default owner" whose reviews drive the public site.
#
# Phase 1 is single-user: there is no authentication, so public pages and the
# admin act on one owner (see User.default_owner). Phase 2 replaces this with
# a real current_user.
module UsesDefaultOwner
  extend ActiveSupport::Concern

  private

  def owner
    @owner ||= User.default_owner
  end

  def owner_reviews
    owner ? owner.reviews : Review.none
  end
end

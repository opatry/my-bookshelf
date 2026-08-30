# Phase 1 has no authentication and acts on a single default user to which
# reviews are attached. Phase 2 introduces per-user accounts.
#
# This seed is idempotent. The password is irrelevant until auth lands in
# Phase 2, but `has_secure_password` requires one.
default_email = ENV.fetch("DEFAULT_USER_EMAIL", "olivier@example.org")
default_password = ENV.fetch("DEFAULT_USER_PASSWORD", "change-me")

User.find_or_create_by!(email: default_email) do |user|
  user.name = "Olivier"
  user.password = default_password
  user.password_confirmation = default_password
end

puts "Seeded default user: #{default_email}"

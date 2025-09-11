# frozen_string_literal: true

source "https://rubygems.org"

UNMAGIC_GEM_ROOT_PATH = ENV["UNMAGIC_GEM_ROOT_PATH"]
[
  "unmagic-support"
].each do |unmagic_gem_name|
  if UNMAGIC_GEM_ROOT_PATH
    unmagic_gem_path = File.expand_path(File.join(UNMAGIC_GEM_ROOT_PATH, unmagic_gem_name))
    if Dir.exist?(unmagic_gem_path)
      gem unmagic_gem_name, path: unmagic_gem_path
      next
    end
  end
  gem unmagic_gem_name, git: "git@github.com:unreasonable-magic/#{unmagic_gem_name}"
end

gemspec

group :development do
  gem "rspec"
  gem "rubocop-rails-omakase", require: false
end

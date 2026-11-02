# frozen_string_literal: true

# Chooses an Xcode installation from the apps found in /Applications.
module XcodeSelector
  # Released versions only: Xcode_16.app, Xcode_16.4.app, Xcode_16.4.1.app.
  # Betas, plain "Xcode.app" and other names are ignored on purpose.
  APP_NAME = /\AXcode_(\d+)(?:\.(\d+))?(?:\.(\d+))?\.app\z/

  # The path of the newest Xcode with the given major version, or nil.
  # Equal versions (for example a symlink) are resolved by path, so the
  # result does not depend on the order of `paths`.
  def self.newest(paths, major:)
    candidates = paths.filter_map do |path|
      match = APP_NAME.match(File.basename(path))
      next unless match && match[1].to_i == major

      version = Gem::Version.new([match[1], match[2] || "0", match[3] || "0"].join("."))
      [version, path]
    end

    candidates.max_by { |version, path| [version, path] }&.last
  end
end
# frozen_string_literal: true

# Finds the local Swift packages of the repository.
module Packages
  DIRECTORY = "Packages"

  # Names of the directories under Packages/ that contain a Package.swift, sorted.
  def self.all(root)
    Dir.glob(File.join(root, DIRECTORY, "*", "Package.swift"))
       .map { |manifest| File.basename(File.dirname(manifest)) }
       .sort
  end

  def self.path(root, name)
    File.join(root, DIRECTORY, name)
  end

  # True when the package has production code (a Sources directory).
  # SehatLocalizationChecks is test-only, so it has none.
  def self.production_code?(root, name)
    Dir.exist?(File.join(path(root, name), "Sources"))
  end
end
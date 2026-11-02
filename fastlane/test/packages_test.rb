# frozen_string_literal: true

require "fileutils"
require "minitest/autorun"
require "tmpdir"
require "packages"

class PackagesTest < Minitest::Test
  def test_all_returns_sorted_names_of_directories_that_have_a_manifest
    with_repo do |root|
      make_package(root, "SehatDomain")
      make_package(root, "SehatCore")
      FileUtils.mkdir_p(File.join(root, "Packages", "NotAPackage"))
      File.write(File.join(root, "Packages", "README.md"), "x")

      assert_equal %w[SehatCore SehatDomain], Packages.all(root)
    end
  end

  def test_all_returns_empty_when_there_is_no_packages_directory
    with_repo do |root|
      assert_equal [], Packages.all(root)
    end
  end

  def test_path_points_into_the_packages_directory
    assert_equal "/r/Packages/SehatCore", Packages.path("/r", "SehatCore")
  end

  def test_production_code_is_true_only_when_the_package_has_sources
    with_repo do |root|
      make_package(root, "WithSources", sources: true)
      make_package(root, "TestOnly")

      assert Packages.production_code?(root, "WithSources")
      refute Packages.production_code?(root, "TestOnly")
    end
  end

  private

  def with_repo(&block)
    Dir.mktmpdir(&block)
  end

  def make_package(root, name, sources: false)
    directory = File.join(root, "Packages", name)
    FileUtils.mkdir_p(directory)
    FileUtils.mkdir_p(File.join(directory, "Sources")) if sources
    File.write(File.join(directory, "Package.swift"), "// manifest")
  end
end
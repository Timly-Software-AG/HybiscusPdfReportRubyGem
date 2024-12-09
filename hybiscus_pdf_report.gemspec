# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require_relative "lib/hybiscus_pdf_report/version"

Gem::Specification.new do |spec|
  spec.name = "hybiscus_pdf_report"
  spec.version = HybiscusPdfReport::VERSION
  spec.authors = ["Philipp Baumann"]
  spec.email = ["philipp.baumann@timly.com"]

  spec.summary = "API Wrapper for the Hybiscus.dev PDF reports generator"
  spec.description = "This gem provides a simple access using Ruby to the Hybiscus.dev PDF reports generator API."
  spec.homepage = "https://hybiscus.dev/"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["source_code_uri"] = "https://github.com/Timly-Software-AG/HybiscusPdfReportRubyGem"
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .gitlab-ci.yml appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday", "~> 1.10"
  spec.add_development_dependency "pry"
end

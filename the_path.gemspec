
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "the_path/version"

Gem::Specification.new do |spec|
  spec.name          = "the_path"
  spec.version       = ThePath::VERSION
  spec.authors       = ["Noah Gibbs"]
  spec.email         = ["the.codefolio.guy@gmail.com"]

  spec.summary       = %q{A 'choose-your-own-adventure' style DSL for bulk email services such as MailChimp.}
  spec.description   = %q{The_path lets you write email chains and classes in a convenient DSL. After building a simple DSL structure for a series of emails, they can be loaded into a mailing service such as MailChimp for use with real humans.}
  spec.homepage      = "https://github.com/noahgibbs/the_path"
  spec.license       = "MIT"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"

  spec.add_development_dependency "gibbon"
end

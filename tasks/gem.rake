require 'rubygems/package_task'
require 'rake/clean'

CLOBBER.include('pkg')

namespace :gem do
  GEM_SPEC = Gem::Specification.new do |s|
    unless s.respond_to?(:add_development_dependency)
      puts 'The gem spec requires a newer version of RubyGems.'
      exit(1)
    end

    s.name = PKG_NAME
    s.version = PKG_VERSION
    s.author = PKG_AUTHOR
    s.email = PKG_AUTHOR_EMAIL
    s.summary = PKG_SUMMARY
    s.description = PKG_DESCRIPTION

    s.files = PKG_FILES.to_a
    s.executables << 'google-api'

    s.extra_rdoc_files = %w( README.md )
    s.rdoc_options.concat ['--main',  'README.md']

    # Dependencies used in the main library
    s.add_runtime_dependency('signet', '>= 0.3.1')
    s.add_runtime_dependency('addressable', '>= 2.2.3')
    s.add_runtime_dependency('autoparse', '>= 0.3.1')
    s.add_runtime_dependency('faraday', '~> 0.7.0')
    s.add_runtime_dependency('multi_json', '>= 1.3.0')
    s.add_runtime_dependency('extlib', '>= 0.9.15')

    # Dependencies used in the CLI
    s.add_runtime_dependency('launchy', '>= 2.0.0')

    # Dependencies used in the examples
    s.add_development_dependency('sinatra', '>= 1.2.0')

    s.add_development_dependency('rake', '>= 0.9.0')
    s.add_development_dependency('rspec', '~> 1.2.9')
    s.add_development_dependency('rcov', '>= 0.9.9')
    s.add_development_dependency('diff-lcs', '>= 1.1.2')

    s.require_path = 'lib'

    s.homepage = PKG_HOMEPAGE
  end

  Gem::PackageTask.new(GEM_SPEC) do |p|
    p.gem_spec = GEM_SPEC
    p.need_tar = true
    p.need_zip = true
  end

  desc 'Show information about the gem'
  task :debug do
    puts GEM_SPEC.to_ruby
  end

  desc "Generates .gemspec file"
  task :gemspec do
    spec_string = GEM_SPEC.to_ruby

    begin
      Thread.new { eval("$SAFE = 3\n#{spec_string}", binding) }.join
    rescue
      abort "unsafe gemspec: #{$!}"
    else
      File.open("#{GEM_SPEC.name}.gemspec", 'w') do |file|
        file.write spec_string
      end
    end
  end

  desc 'Install the gem'
  task :install => ['clobber', 'gem:package'] do
    sh "#{SUDO} gem install --local pkg/#{GEM_SPEC.full_name}"
  end

  desc 'Uninstall the gem'
  task :uninstall do
    installed_list = Gem.source_index.find_name(PKG_NAME)
    if installed_list &&
        (installed_list.collect { |s| s.version.to_s}.include?(PKG_VERSION))
      sh(
        "#{SUDO} gem uninstall --version '#{PKG_VERSION}' " +
        "--ignore-dependencies --executables #{PKG_NAME}"
      )
    end
  end

  desc 'Reinstall the gem'
  task :reinstall => [:uninstall, :install]
end

desc 'Alias to gem:package'
task 'gem' => 'gem:package'

task 'gem:release' => 'gem:gemspec'

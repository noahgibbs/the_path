module ThePath
  class Command
    def run
        raise "Implement me!"
    end
  end

  class RepoCommand < Command
    def initialize
        unless File.exist?("the_path_config.rb")
            raise "Not in a repo for repo command #{self.class.name}!"
        end

        ret_val = load "the_path_config.rb"
    end
  end

  class InitCommand < Command
    def run
        File.open("the_path_config.rb", "w") do |f|
          f.print <<CONFIG
ThePath::Config.new do
end
CONFIG
        end
    end
  end

  class SyncCommand < RepoCommand
    def run
      FileUtils.mkdir("cache") unless File.exist?("cache")
      impl = ThePath::MailChimpImpl.new(repo_path: "cache/", freshness: 24 * 60 * 60)
      #impl.load_all_resources()

      raise "Finish implementing!"
    end
  end

  class BackupCommand < RepoCommand
    def run
      FileUtils.mkdir("cache") unless File.exist?("cache")
      impl = ThePath::MailChimpImpl.new(repo_path: "cache/", freshness: 1)
      impl.load_all_resources()
    end
  end

  class PeekCommand < RepoCommand
    def run
      impl = ThePath::MailChimpImpl.new(repo_path: "cache/", freshness: 24 * 60 * 60)

      config = ThePath::Config.config_for_dir(File.expand_path(Dir.pwd))


      # TODO: match up campaigns to titles (identifiers)
      # TODO: figure out which list to use

      cached_resource_get("campaigns")

      actions = Dir["*.path"].to_a.map do |pathfile|
        config.action(File.read pathfile)
      end

      config.actions.each do |action|
        STDERR.puts "Action: #{action.inspect}"
      end
    end
  end
end

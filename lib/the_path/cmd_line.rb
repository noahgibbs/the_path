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

        load "the_path_config.rb"
    end
  end

  class InitCommand < Command
    def run
        File.open("the_path_config.rb", "w") do |f|
          f.print <<CONFIG
THE_PATH = ThePath::Config.new do
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

      actions = Dir["*.path"].to_a.map do |pathfile|
        THE_PATH.action(File.read pathfile)
      end

      THE_PATH.actions.each do |action|
        STDERR.puts "Action: #{action.inspect}"
      end
    end
  end
end

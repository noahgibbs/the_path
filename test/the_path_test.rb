require "test_helper"

class ThePathTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::ThePath::VERSION
  end

  def test_load_repo
    Dir.chdir "#{__dir__}/repos/tiny" do
        cmd = ThePath::PeekCommand.new
        cmd.run
    end
  end
end

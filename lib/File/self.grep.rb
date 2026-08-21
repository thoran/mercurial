# File/self.grep.rb
# File.grep

# 20260609
# 0.0.1

# Description: This returns a string (probably a number of lines) which is the result of grepping a file, similar to the grepping of a file on the command line.

# Changes:
# -/0: Include missing require.
# 1. + require 'Regexp/to_regexp'

require 'Regexp/to_regexp'
require 'String/grep'
require 'String/to_regexp'

class File
  def self.grep(file_path, pattern)
    pattern = pattern.to_regexp
    read(file_path).grep(pattern)
  end
end

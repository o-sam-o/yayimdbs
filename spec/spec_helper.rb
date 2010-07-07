require 'rubygems'
require 'rake'
require 'yay_imdbs'

# http://codefluency.com/2010/05/05/a-bandaid-for-rcov-on-ruby-1-9/
if defined?(Rcov)
  class Rcov::CodeCoverageAnalyzer
    def update_script_lines__
      if '1.9'.respond_to?(:force_encoding)
        SCRIPT_LINES__.each do |k,v|
          v.each { |src| src.force_encoding('utf-8') }
        end
      end
      @script_lines__ = @script_lines__.merge(SCRIPT_LINES__)
    end
  end
end
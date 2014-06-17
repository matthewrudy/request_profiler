require 'ruby-prof'

module Rack
  class RequestProfiler
    def initialize(app, options = {})
      @app = app
      @printer = options[:printer] || ::RubyProf::GraphHtmlPrinter
      @exclusions = options[:exclude]
    end

    def call(env)
      request = Rack::Request.new(env)
      mode = profile_mode(request)

      if mode
        ::RubyProf.measure_mode = mode
        ::RubyProf.start
      end
      status, headers, body = @app.call(env)

      if mode
        result = ::RubyProf.stop
        [200, {}, write_result(result)]

      else
        [status, headers, body]
      end
    end

    def profile_mode(request)
      mode_string = request.params["profile_request"]
      if mode_string
        if mode_string.downcase == "true" or mode_string == "1"
          ::RubyProf::PROCESS_TIME
        else
          ::RubyProf.const_get(mode_string.upcase)
        end
      end
    end

    def format(printer)
      case printer
      when ::RubyProf::FlatPrinter
        'txt'
      when ::RubyProf::FlatPrinterWithLineNumbers
        'txt'
      when ::RubyProf::GraphPrinter
        'txt'
      when ::RubyProf::GraphHtmlPrinter
        'html'
      when ::RubyProf::DotPrinter
        'dot'
      when ::RubyProf::CallTreePrinter
        "out.#{Process.pid}"
      when ::RubyProf::CallStackPrinter
        'html'
      else
        'txt'
      end
    end

    def prefix(printer)
      case printer
      when ::RubyProf::CallTreePrinter
        "callgrind."
      else
        ""
      end
    end

    def write_result(result)
      result.eliminate_methods!(@exclusions) if @exclusions
      printer = @printer.new(result)
      out = StringIO.new
      printer.print(out)
      out
    end
  end
end

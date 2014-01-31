require "tempfile"
require "phantomjs/configuration"
require "phantomjs/version"
require "phantomjs/errors"

class Phantomjs

  def self.run(path, handler, *args, &block)
    Phantomjs.new.run(path, handler, *args, &block)
  end

  def run(path, handler, *args)
    epath = File.expand_path(path)
    raise NoSuchPathError.new(epath) unless File.exist?(epath)
    block = block_given? ? Proc.new : nil
    execute(epath, handler, args, block)
  end

  def self.inline(script, handler, *args, &block)
    Phantomjs.new.inline(script, handler, *args, &block)
  end

  def inline(script, handler, *args)
    file = Tempfile.new('script.js')
    file.write(script)
    file.close
    block = block_given? ? Proc.new : nil
    execute(file.path, handler, args, block)
  end

  def self.configure(&block)
    Configuration.configure(&block)
  end

  private

  def execute(path, handler, arguments, block)
    begin
      if block
        IO.popen([exec, path, arguments].flatten).each_line do |line|
          block.call(line)
        end
      elsif handler && defined?(EM)
        EM.popen([exec, path, arguments].join(" "), handler)
      else
        IO.popen([exec, path, arguments].flatten).read
      end
    rescue Errno::ENOENT
      raise CommandNotFoundError.new('Phantomjs is not installed')
    end
  end

  def exec
    Phantomjs::Configuration.phantomjs_path
  end
end

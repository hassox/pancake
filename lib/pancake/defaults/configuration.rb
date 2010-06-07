class Pancake::PancakeConfig < Pancake::Configuration::Base
  default :log_path,        Proc.new{ "log/pancake_#{Pancake.env}.log"}
  default :log_level,       :info
  default :log_delimiter,   " ~ "
  default :log_auto_flush,  true
  default :log_to_file,     Proc.new{ Pancake.env == "production" }
  default :log_stream,      Proc.new{ _log_stream }

  def _log_stream
    if Pancake.configuration.log_to_file
      log_dir = File.expand_path(File.join(Pancake.root, File.dirname(log_path)))
      FileUtils.mkdir_p(log_dir)
      log = File.join(log_dir, File.basename(log_path))
      File.open(log, (File::WRONLY | File::APPEND | File::CREAT))
    else
      STDOUT
    end
  end

  def reset_log_stream!
    values.delete(:log_stream)
  end

  def stacks(label = nil)
    @stacks ||=  {}
    result = label.nil? ? @stacks : @stacks[label]
    yield result if block_given?
    result
  end

  def configs(label = nil)
    @configs ||= Hash.new do |h,k|
      if (k.is_a?(Class) || k.is_a?(Module)) && defined?(k::Configuration)
        h[k] = k::Configuration.new
      else
        nil
      end
    end
    result = label.nil? ? @configs : @configs[label]
    yield result if block_given?
    result
  end
end

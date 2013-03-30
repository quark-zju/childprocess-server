require 'drb/drb'
require 'childprocess'
require 'thread'
require 'tempfile'

class ChildProcess::Server

  # Connect to existing DRb service.
  #
  # @param uri [String] drb path
  # @return [DrbObject<Server>] remote server
  def self.connect(uri)
    DRb.start_service
    DRbObject.new_with_uri(uri)
  end

  # Start DRb service.
  #
  # @param wait [Bool] whether to block and wait for drb service to end
  # @param uri [String] drb path
  # @return [DRb::DRbServer]
  def start_service(uri, wait = true)
    server = DRb.start_service(uri, self)
    DRb.thread.join if wait
    server
  end

  def initialize
    @processes = {}
    @mutex = Mutex.new
  end

  # Launch a process in background.
  #
  # @param commands [Array<String>] commands
  # @return [Integer] pid
  def launch(*commands)
    output = Tempfile.new('cps-out')
    output.sync = true

    process = ChildProcess.build(*commands)
    process.io.stdout = process.io.stderr = output
    process.duplex = true
    process.start

    pid = process.pid
    access_processes do |processes|
      processes[pid] = process
    end
    pid
  end

  # Read output, will not block.
  #
  # @param pid [Integer] process id
  # @return [String] output so far, <tt>nil</tt> on error
  def read_output(pid)
    access_processes do |processes|
      File.read(processes[pid].io.stdout.path) rescue nil 
    end
  end

  # Write to input.
  #
  # @param pid [Integer] process id
  def write_input(pid, content)
    access_processes do |processes|
      processes[pid] && processes[pid].io.stdin.write(content) rescue nil
    end
  end

  # List process ids managed by this server.
  #
  # @return [Array<Integer>] process ids
  def list_pids
    access_processes do |processes|
      processes.keys
    end
  end

  # Check whether a process managed by this server is alive.
  #
  # @param pid [Integer] process id
  # @return [Bool] whether that process is alive,
  #                <tt>nil</tt> if that process is not managed by this server
  def alive?(pid)
    access_processes do |processes|
      processes[pid] && processes[pid].alive?
    end
  end

  # Stop a process managed by this server.
  #
  # @param pid [Integer] process id
  def stop(pid)
    access_processes do |processes|
      processes[pid] && processes[pid].stop
    end
  end

  # Clean up exited processes.
  def clean_up
    access_processes do |processes|
      processes.values.select(&:exited?).each do |process|
        process.io.stdout.path.unlink rescue nil
      end
      processes.delete_if { |_, process| process.exited? }
      # Do not leak @processes outside
      # We are using dRuby, keep input/output objects simple
      nil
    end
  end

  protected

  # Access processes, exclusively.
  def access_processes
    @mutex.synchronize do
      yield @processes
    end
  end

end

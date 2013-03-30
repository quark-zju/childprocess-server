require 'spec_helper'
require 'childprocess/server'

shared_examples_for 'common-server-tests' do
  describe 'for external processes' do
    it 'runs "true"' do
      pid = server.launch('true')
      pid.should > 0
      server.list_pids.should include(pid)
      server.read_output(pid).should be_empty
      server.stop(pid)
      server.alive?(pid).should be_false
      server.clean_up.should be_nil
      server.alive?(pid).should be_nil
      server.list_pids.should_not include(pid)
    end

    it 'runs "cat" interactively' do
      pid = server.launch('stdbuf', '-o0', 'cat')
      server.alive?(pid).should be_true
      (server.read_output(pid) || '').should be_empty
      server.write_input(pid, "a\n")
      sleep 0.1
      server.read_output(pid).should == "a\n"
      server.write_input(pid, "bc\n")
      sleep 0.1
      server.read_output(pid).should == "a\nbc\n"
      server.stop(pid)
      server.alive?(pid).should be_false
      server.clean_up.should be_nil
    end
  end

  describe 'for processes not managed' do
    it '#read_output' do
      server.read_output($$).should be_nil
    end

    it '#alive?' do
      server.alive?($$).should be_nil
    end

    it 'stop' do
      expect do
        server.stop($$)
      end.to_not raise_error
    end

    it '#write_input' do
      expect do
        server.write_input($$, 'test')
      end.to_not raise_error
    end
  end
end 

describe 'standalone' do
  let(:server) { ChildProcess::Server.new }

  it_should_behave_like 'common-server-tests'
end

describe 'client-server' do
  SOCKET_FILE = File.join(Dir.tmpdir, "csspec-#{$$}.socket")
  DRB_URI = "drbunix://#{SOCKET_FILE}"
  THREAD_COUNT = 10
  CLIENT_COUNT = 4

  before(:all) do
    server = ChildProcess::Server.new
    @service = server.start_service(DRB_URI, false)
  end

  after(:all) do
    @service.stop_service
    File.unlink(SOCKET_FILE) rescue nil
  end

  let(:server) { ChildProcess::Server.connect(DRB_URI) }

  it_should_behave_like 'common-server-tests'

  it 'accepts multiple connections' do
    expect do
      clients = CLIENT_COUNT.times.map { ChildProcess::Server.connect(DRB_URI) }
      pids = clients.map { |client| client.launch('sleep', '3') }
      server.list_pids.should include(*pids)
      pids.each { |pid| server.stop(pid) }
      server.clean_up
    end.to_not change { server.list_pids }
  end

  it 'handle concurrent requests' do
    expect do
      threads = THREAD_COUNT.times.map do
        Thread.new do
          texts = CLIENT_COUNT.times.map { rand.to_s }
          clients = CLIENT_COUNT.times.map { ChildProcess::Server.connect(DRB_URI) }
          pids = clients.map.with_index do |client, i|
            client.launch('echo', texts[i])
          end
          clients[0].list_pids.should include(*pids)
          sleep 0.1
          pids.map.with_index do |pid, i|
            clients[rand(0...clients.size)].read_output(pid).should == "#{texts[i]}\n"
          end
        end
      end
      threads.each(&:join)
      sleep 0.1
      server.clean_up
    end.to_not change { server.list_pids }
  end
end

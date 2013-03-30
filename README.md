# childprocess-server

Manage and interact with processes, remotely (via dRuby).

## Installation

```bash
gem install childprocess-server
```

## Usage

### Standalone

```ruby
require 'childprocess-server'
server = ChildProcess::Server.new

# Run a process
pid = server.launch('sleep', '1000')
server.alive?(pid) # => true
server.stop(pid)
server.alive?(pid) # => false

# Run 'echo', get output
pid = server.launch('echo', 'hello')
server.read_output(pid) # => "hello\n"
server.alive?(pid) # => false

# Run 'cat', write stdin interactively
pid = server.launch('cat')
server.write_input(pid, "foo\n")
server.read_output(pid) # => "foo\n"
server.write_input(pid, "bar\n")
server.read_output(pid) # => "foo\nbar\n"
server.stop(pid)

# List all process ids managed
# Note: exited processes are also listed.
server.list_pids # => [ ... ]

# Clean up
server.clean_up
server.list_pids # => []
```

### Client / Server

```ruby
DRB_URI = 'drbunix://tmp/a.socket'

# Server side
ChildProcess::Server.new.start_service(DRB_URI) # will block by default

# Client side
server = ChildProcess::Server.connect(DRB_URI)
pid = server.launch('sort', '-n')
server.write_input(pid, "20\n10\n2\n1\n")
server.read_output(pid) # => "1\n2\n10\n20\n"
```

## Notes

* This library is thread-safe.
* This library does not have authentic feature.
  Set file system permissions or firewall for security.
* After `stop`, output can still be read using `read_output`,
  because outputs are stored in temporary files.
  Use `clean_up` to delete them immediately.
  Otherwise they are deleted when server exits.
* If `read_output` or `write_input` encounters errors,
  they just return `nil` instead of raising an error.

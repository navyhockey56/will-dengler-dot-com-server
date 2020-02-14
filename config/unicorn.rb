# frozen_string_literal: true

#####################
# About
# This file is responsible for running unicorn. Unicorn will start the
# SideTexter Server
# By default, the server will run on port 4567.

dir = Dir.pwd

worker_processes 1
working_directory dir

timeout 30

# Set the socket
listen File.join(dir, 'tmp/sockets/unicorn.sock'), backlog: 64

# Set the process id path
pid File.join(dir, 'tmp/pids/unicorn.pid')

# Set log file paths
stderr_path File.join(dir, 'logs/unicorn.stderr.log')
stdout_path File.join(dir, 'logs/unicorn.stdout.log')

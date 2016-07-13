capistrano_sentinel
===================

Overview
--------

CapistranoSentinel is a simple ruby implementation that allows you to emit websocket events before a task is invoked by Capistrano.

This gem only has the websocket client that emit events to a default host and port , see here more details: **[Configuration options](#configuration-options)**

You can change that configuration following the description below

Requirements
------------

1.	[websocket >= 1.2](https://github.com/imanel/websocket-ruby)

Compatibility
-------------

[MRI 2.x](http://www.ruby-lang.org)

Ruby 1.8 , 1.9 is not officially supported. We will accept further compatibilty pull-requests but no upcoming versions will be tested against it.

Rubinius and Jruby support is dropped.

Installation Instructions
-------------------------

Add the following to your Gemfile:

```ruby
  gem "capistrano_sentinel"
```

Add the following to your Capfile

```ruby
  require 'capistrano_sentinel'
```

Configuration options
=====================

```ruby
  CapistranoSentinel.configure do |config|

    # if the connection needs to be secure ( using port 443)
    config.secure  = false

    # the host on  which the server is listening to connections
    config.host    = '0.0.0.0'

    # the port on  which the server is listening to connections
    config.port    = 1234

    # the path to which the server is listening to connections
    config.path    = '/ws'

    # if it receives a ping message, does it need to respond automatically
    config.auto_pong = true

    # how many bites can it read from the connection
    config.read_buffer_size = 2048

    # if the conection can reconnect in case the connection was unsuccessful
    config.reconnect = false

    # how many times can retry the connection
    config.retry_time = 0  

    # if this is enabled, the task will sleep until the socket receives a message back in this format
    # {"action"=>"invoke", "task"=><task_name>, "job_id"=><job_id>, "approved"=>"yes"},
    # where the task_name needs to be the task that is waiting for approval and
    # the job_id needs to be set using ENV['multi_cap_job_id'], for parallel processing
    # ( if the job id is missing , will be automatically generated with SecureRandom.uuid)
    config.wait_execution = true

    # if this is enabled, this will hook into stdin and stdout before a task is executed and if stdin is needed
    # than will publish a message in this format {"action":"stdout","question":"<the stdout message>",default:"", "job_id":"<job_id>" }
    # where question key is done by reading the last message printed by the task and parsing the message to detect
    # if the message is a question . If it is a question in this format ( e.g. "where do you live?(Y/N)")
    # then the question will be sent as "where do you live?" and the default will be "Y/N"
    config.hook_stdin_and_stdout = true
  end
```

All websocket messages are published in this format:

```ruby
{     
  "client_action":"publish",
  "channel":"celluloid_worker_<job_id>",
  "data": {}
}
```

Where the **data** will have as value the example listed below when using **wait_execution** set to **TRUE**:

E.g. Mesage sent before a task is executed:

```ruby
{     
  "action"=> "invoke",
  "task"=> <task_name>,
  "job_id"=> <job_id>
}
```

Or when using **hook_stdin_and_stdout** set to **TRUE**:

And E.g.

```ruby
  {
    "action": "stdout",
    "question": < if the stdout contains ? or : will use the text before that character >,
    'default': <if the stdout message cotains () will use the text from within, otherwise string blank >,
    "job_id": "<job_id>"
  }
```

Usage Instructions
==================

Just run capistrano task like you normally do and you will get websocket notifications to that host and port configured.

```shell
#<development_stage> - the name of one of the stages you have in your application
#<task_name> - the capistrano task that you want to execute ( example: 'deploy' )

bundle exec cap  <development_stage> <task_name>  
```

Testing
-------

To test, do the following:

1.	cd to the gem root.
2.	bundle install
3.	bundle exec rake

Contributions

---

Please log all feedback/issues via [Github Issues](http://github.com/bogdanRada/capistrano_sentinel/issues). Thanks.

Contributing to capistrano_sentinel
-----------------------------------

-	Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
-	Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
-	Fork the project.
-	Start a feature/bugfix branch.
-	Commit and push until you are happy with your contribution.
-	Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
-	Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

Copyright
---------

Copyright (c) 2016 bogdanRada. See LICENSE.txt for further details.

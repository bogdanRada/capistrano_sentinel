capistrano_sentinel
===================

Overview
--------

CapistranoSentinel is a simple ruby implementation that allows you to emit websocket events before a task is invoked by Capistrano.

This gem only has the websocket client that emit events to a host (default 0.0.0.0 port 1234 and path /ws)

Currently there is no posibility to change the default configuration becasue this was just released few days ago, but this will be added soon

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

Testing
-------

Usage Instructions
==================

Just run capistrano task like you normally do and you will get websocket notifications to that host and port configured.

```shell
#<development_stage> - the name of one of the stages you have in your application
#<task_name> - the capistrano task that you want to execute ( example: 'deploy' )

bundle exec cap  <development_stage> <task_name>  
```

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

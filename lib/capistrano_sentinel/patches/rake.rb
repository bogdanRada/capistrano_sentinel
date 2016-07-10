Rake::Task.class_eval do
  alias_method :original_execute, :execute

  def execute(*args)
    rake = CapistranoSentinel::RequestHooks.new(self)
    rake.automatic_hooks do
      original_execute(*args)
    end
  end
end

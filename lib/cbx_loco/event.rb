class CbxLoco::Event
  def initialize
    @tasks = {}.with_indifferent_access
  end

  def on(event, &block)
    @tasks[event] = [] if !@tasks[event].kind_of?(Array)
    @tasks[event].push(block)
  end

  def tasks
    @tasks
  end

  def emit(event_name)
    callables = tasks[event_name] || []
    callables.each { |callable| callable.call }
  end
end

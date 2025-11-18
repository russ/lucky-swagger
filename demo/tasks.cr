require "lucky_task"
require "lucky-swagger"

# Load all tasks
require "./tasks/**"
require "./src/actions/**"

# Run the task runner
LuckyTask::Runner.run

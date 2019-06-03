# Provides controller for accessing and manipulating random people
#
class RandomsController < ApplicationController
  view_context RandomsViewContext

  # Collect and render between 20 and 35 random people
  #
  # Determines a random id within the limit to award as the winner.
  # This demonstrates the ability to utilize the locals set within the
  # controller in the view_context methods.
  def index
    t1 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    limit = rand(20..35)
    randoms = RandomPerson.all(limit: limit)
    t2 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    render locals: {
      randoms: randoms,
      winner_id: randoms[rand(0...limit)].id,
      elapsed_millis: (t2 - t1) * 1000
    }
  end
end
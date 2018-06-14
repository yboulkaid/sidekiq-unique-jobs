# frozen_string_literal: true

RSpec.describe UntilExecuted2Job do
  it_behaves_like 'sidekiq with options', options: {
    'backtrace'    => 10,
    'queue'        => :working,
    'retry'        => 1,
    'lock_timeout' => 0,
    'unique'       => :until_executed,
  }

  it_behaves_like 'a performing worker', args: %w[one two]
end

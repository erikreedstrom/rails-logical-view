# Provides the view context for the randoms controller actions.
#
module RandomsViewContext

  # Provides the average spend for all randoms
  #
  def avg_spend(randoms)
    @avg_spend || sum_spend(randoms) / randoms.count
  end

  # Provides a minmax list of randoms by spend
  #
  def minmax_spenders(randoms)
    @minmax_spend || randoms.minmax_by(&:spend)
  end

  # Provides the total spend for all randoms
  #
  def sum_spend(randoms)
    @sum_spend || randoms.reduce(0) { |m, r| m + r.spend }
  end

  # Provides the title attribute for the current page
  #
  # A default implementation is provided by the layout view_context
  # that we override for this view. This allows for sane fallbacks
  # as well as page specific customization.
  def title(randoms:, **_rest)
    case action_name
    when 'index'
      "#{randoms.count} Random People - LogicalView"
    else
      super
    end
  end

  # Provides a list of vowels and their respective counts for all names
  #
  def vowel_counts(randoms)
    randoms
      .map(&:name)
      .reduce('') { |m, n| m + n.gsub(/[^aeiou]/, '') }
      .split('')
      .group_by { |l| l }
      .map { |k, v| [k, v.count] }
      .sort
  end

  # Determines if the passed  person is the winner.
  #
  # A contrived example of destructuring data from the locals assignment
  # as well as passed args to invoke view specific logic.
  def winner?(id, winner_id:, **_rest)
    id == winner_id
  end
end
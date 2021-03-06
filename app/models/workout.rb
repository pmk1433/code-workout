class Workout < ActiveRecord::Base
	has_and_belongs_to_many :exercises
	has_and_belongs_to_many :tags

	validates :name,
    presence: true,
    length: {:minimum => 1, :maximum => 50},
    format: {
      with: /[a-zA-Z0-9\-_: .]+/,
      message: 'Workout name must be 50 characters or less and consist only of ' \
        'letters, digits, hyphens (-), underscores (_), spaces ( ), colons (:) ' \
        ' and periods (.).'
    }


  def add_exercise(ex_id)
    duplicate = self.exercises.bsearch{|x| x.id == ex_id}
    if( duplicate.nil? )
      exists = Exercise.find(ex_id)
      if( !exists.nil? )
        self.exercises << exists
        exists.workouts << self
        self.order = self.exercises.size
      end
    end
  end

  # returns a hash of exercise experience points (XP) with {:scored => ___, :total => ___, :percent => ____}
  def xp(u_id)
    xp = Hash.new
    xp[:scored] = 0
    xp[:total] = 0
    exs = self.exercises
    exs.each do |x|
      x_attempt = x.attempts.where(:user_id => u_id).pluck(:experience_earned)
      x_attempt.each do |a|
        xp[:scored] = xp[:scored] + a
      end
      xp[:total] = xp[:total] + x.experience
    end
    xp[:total] > 0 ? xp[:percent] = xp[:scored].to_f/xp[:total].to_f*100 : xp[:percent] = 0
    return xp
  end

  def all_tags
    coll = self.tags.pluck(:tag_name).uniq
    exs = self.exercises
    exs.each do |x|
      x_tags = x.tags.pluck(:tag_name).uniq
      x_tags.each do |another|
        if( coll.index(another).nil? )
          coll.push(another)
        end
      end
    end
    return coll
  end

  def highest_difficulty
    diff = 0
    exs = self.exercises
    exs.each do |x|
      if( !x.difficulty.nil? && x.difficulty > diff )
        diff = x.difficulty
      end
    end
    return diff.to_i
  end

  #~ Class methods ............................................................
  def self.search(terms)
    term_array = terms.split
    term_array.each do |term|
      term = "%" + term + "%"
    end
    return Workout.joins(:tags).where{tags.tag_name.like_any term_array}
  end

  def self.xp_distribution(u_id, w_id)
    w = Workout.find(w_id)
    results = w.xp(u_id)
    earned = results[:scored]
    earned_per = results[:percent]
    total = results[:total]
    remaining = 0
    exs = w.exercises
    exs.each do |x|
      x_attempt = x.attempts.where(:user_id => u_id).pluck(:experience_earned)
      x_earned = 0
      x_attempt.each do |a|
        x_earned += a
      end
      remaining += x.experience-x_earned
    end
    remaining_per = remaining/total.to_f*100
    gap = total-earned-remaining
    gap_per = 100-earned_per-remaining_per
    return [earned,remaining,gap,earned_per,remaining_per,gap_per]
  end
end

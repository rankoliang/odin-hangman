# frozen_string_literal: true
require 'yaml'

# srand 1111

class String
  def indexes(ch)
    indexes = []
    while char_index = index(ch, indexes.last ? indexes.last + 1 : 0)
      indexes.push(char_index)
    end
    indexes
  end
end

class Game
  attr_reader :successful_attempts
  def initialize(attempts = 15)
    self.attempts = attempts
  end

  def player_feedback
    self.successful_attempts.map{ |letter| letter.nil? ? '_' : letter}.join
  end

  def play()
    generate_word unless self.word
    while successful_attempts.any? {|letter| letter.nil?} && self.attempts.positive?
      print "#{player_feedback} #{attempts} #{attempts > 1 ? 'tries' : 'try'} left\tGuess: "
      guess = gets.chomp.downcase
      # Saves and exits the game
      save_game if guess == 'save'
      unless /^[a-z]$/i.match(guess)
        puts 'Guess a letter!'
        redo
      end
      word.indexes(guess).each do |index|
        successful_attempts[index] = guess 
      end
      self.attempts -= 1
    end
    puts "#{player_feedback} was your final guess. The word was #{word}!"
  end

  def save_game(save_dir='saves')
    Dir.mkdir save_dir unless Dir.exists? save_dir
    # sets own save file name
    unless self.save_file_name
      next_file_num = Dir.glob(self.class.save_file_glob).map { |file| File.basename(file,'.save').split('-').last.to_i }.max + 1 || 0
      save_file = "slot-#{next_file_num}.save"
      self.save_file_name = save_file
    end
    File.open(File.join(save_dir, self.save_file_name), 'w') do |file|
      file.puts Marshal::dump(self)
    end
    puts "Game saved to #{self.save_file_name}"
    exit()
  end

  def generate_word
    begin
      self.word = File.open('5desk.txt', 'r').readlines.sample.chomp
    rescue Errno::ENOENT
      'File does not exist'
    end
    self.successful_attempts = Array.new(word.size)
  end

  def self.load_game(save_file, save_dir = 'saves')
    begin
      Marshal.load(File.open(File.join(save_dir, save_file),'r').read).play
    rescue => exception
      puts 'Could not find save!'
    end
  end

  def self.prompt_load
    puts 'Would you like to start a new game?'
    response = gets.chomp
    if response == 'y'
      self.new.play
    end
    if Dir.exists?('saves') && Dir.glob(self.save_file_glob).size.positive?
      puts "Which save would you like to load?"
      puts Dir.glob(self.save_file_glob).map {|file| File.basename(file, '.save')}.join(', ')
      begin
        slot = /\d*/.match(gets.chomp)[0]
      rescue => exception
        puts 'Could not find save! Starting a new game'
        self.new.play
      else
        self.load_game("slot-#{slot}.save")
      end
    end
  end

  def self.save_file_glob(save_dir = 'saves')
    File.join(save_dir, '*.save')
  end
  
  private

  attr_accessor :word, :attempts, :save_file_name

  attr_writer :successful_attempts
end


Game.prompt_load
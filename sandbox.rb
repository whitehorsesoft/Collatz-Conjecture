# Collatz Conjecture, or 3n + 1 sequences
module Collatz
  require 'sequel'
  db = Sequel.postgres('collatz')
  db.extension :pg_array

  class Sequence < Sequel::Model
  end

  # generate 3n + 1 sequence
  def self.collatz(start)
    result = []
    while start != 1
      result.push start
      start = if start.even?
                start / 2
              else
                start * 3 + 1
              end
    end
    result.push start
    result
  end

  # generates sequences for exponents of 1 - 9 (1, 10, 100…; 2, 20, 200…; etc)
  def self.exponential_tables
    (1..9).each do |i|
      (0..10).each do |j|
        Thread.new do
          n = i * 10**j
          results = collatz n
          # puts sprintf("n: %i, %s", n, results)
          Sequence.create(id: n, nums: Sequel.pg_array(results))
          # t.insert(:id => n, :nums => Sequel.pg_array(results))
        end
      end
    end
    Thread.list.each do |t|
      t.join if t != Thread.current
    end
  end

  def self.char_if_pressed
    begin
      system("stty raw -echo")
      c = nil
      if $stdin.ready?
        c = $stdin.getc
      end
      c.chr if c
    ensure
      system("stty -raw echo")
    end
  end
  
  # generates sequences for a large amount of numbers
  def self.generate
    require 'thwait'
    st = Time.now

    start_id = Sequence.all.last[:id] + 1
    tw = ThreadsWait.new
    # ts = []
    sequence = Sequence.new
    (start_id..start_id + 10**5).each do |i|
      # slowest: 46 secs
      # ts << Thread.new do
      #   sequence.set(id: i, nums: Sequel.pg_array(collatz(i)))
      #   Thread.current.exit
      # end

      thr = Thread.new do
        sequence.set(id: i, nums: Sequel.pg_array(collatz(i)))
        # Thread.current.exit
      end

      # 8 secs
      # if tw.threads.count < 1
      #   tw.join_nowait thr
      # else
      #   tw.join thr
      # end

      thr.join

      if i % 10**4 == 0
        # sequence.save

        c = char_if_pressed
        if c
          puts i
          # slowest: 46 secs
          # while ts.select{|t| t.alive?}.count > 0
          #   puts ts.select(&:alive?).count.to_s + " threads alive"
          # end

          # 8 secs
          # puts tw.threads.count
          # tw.all_waits

          while Thread.list.select{|t| t.alive?}.count > 1
            puts Thread.list.select{|t| t.alive?}.count.to_s + 'threads alive'
            sleep 1
          end
          sequence.save
          sequence = Sequence.new
          puts 'saved'
        end
      end
   end

    # tw.all_waits

    # puts "done, waiting for active to stop"
    # Thread.list.each do |t|
    #   t.join if t != Thread.current
    # end
    sequence.save

    puts format('completed in %f secs', Time.now - st)
  end

  # split array into arrays where each
  # element is a doubling of the
  # subsequent element
  def self.double_num(a)
    a
      .reverse
      .slice_when do |i, j|
      (i * 2) != j
    end
      .to_a[0]
      .count
  end

  # usage: indexes([1,2,3], ->(i){
  #   #return true or false, using i
  #   i.odd? # will result in returning indexes of only odd numbers
  # })
  def self.indexes(arr, code)
    arr
      .each_with_index
      .select { |e| code.call e[0] }
      .map { |e| e[1] }
  end

  # deletes everything from db
  def self.clear
    Sequel.postgres('collatz')[:sequences].delete
  end

  def self.db_setup
    db = Sequel.postgres('collatz')
    db.extension :pg_array

    begin
      db.drop_table(:sequences)
      p 'collatz dropped'
    rescue
    end

    db.create_table :sequences do
      column :id, 'bigint'
      column :nums, 'bigint[]'
    end
    p 'sequences created'
  end

end

# Collatz.db_setup
# Collatz.exponential_tables
# Collatz.generate
Collatz.matrix

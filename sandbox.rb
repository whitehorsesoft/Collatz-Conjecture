require 'sequel'

def db
  d = Sequel.postgres('tester')
  d.extension :pg_array
  return d
end

def collatz(start)
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

def compares
  r = []
  (0..9).each do |i|
    r[i] = []
    (0..9).each do |j|
      r[i].push collatz (i * (j + 1))
    end
  end
  r
end

def tbl
  return db[:collatz]
end

def c
  t = tbl
  (1..9).each do |i|
    (0..10).each do |j|
      Thread.new do
        n = i * 10**j
        results = collatz n
        # puts sprintf("n: %i, %s", n, results)
        t.insert(:id => n, :nums => Sequel.pg_array(results))
      end
    end
  end
  Thread.list.each do |t|
    t.join if t != Thread.current
  end
end

# split array into arrays where each
# element is a doubling of the
# subsequent element
def double_num(a)
  a
    .reverse
    .slice_when do |i, j|
    (i * 2) != j
  end
    .to_a[0]
    .count
end

def odds(a)
  a
    .each_with_index
    .select { |e| e[0].odd? }
    .map { |e| e[1] }
end

def indexes(arr, code)
  arr
    .each_with_index
    .select { |e| code.call e[0] }
    .map { |e| e[1] }
end

def tries
  a = []
  (0..50).each do |_n|
    temp_str = ''
    start_char = rand(97..122)
    end_char = start_char + rand(0..10)
    end_char -= (end_char - 122) if end_char > 122
    (start_char..end_char).each do |c|
      temp_str << c
    end
    a << temp_str
  end
  a
end

def db_setup
  begin
    db.drop_table(:collatz)
    p 'collatz dropped'
  rescue
  end

  db.create_table :collatz do
    column :id, 'bigint'
    column :nums, 'bigint[]'
  end
  p 'collatz created'
end
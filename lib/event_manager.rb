puts 'Event Manager Initialized!'

# contents = File.read('event_attendees.csv')
# puts contents

all_lines = File.readlines('event_attendees.csv')

header = all_lines[0]
lines = all_lines[1..-1]

lines.each do |line|
    columns = line.chomp.split(",")
    name = columns[2]
    puts name
end

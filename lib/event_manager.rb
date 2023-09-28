require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'

def legislators_by_zipcode(zip)
    civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
    civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

    begin
        civic_info.representative_info_by_address(
            address: zip,
            levels: 'country',
            roles: ['legislatorUpperBody', 'legislatorLowerBody']
        ).officials
    rescue
        'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
    end
end

def clean_zipcode(zipcode)
    zipcode.to_s.rjust(5, "0")[0..4]
end

def clean_phone_number(phone_number)
    stripped_phone = phone_number.gsub(/\D/, '')

    if stripped_phone.length == 10
        stripped_phone
    elsif stripped_phone.length == 11 && stripped_phone[0] == "1"
        stripped_phone[1..-1]
    else
        "Invalid phone number"
    end
end

def find_peak_registration_hours(contents)
    # count hours frequency
    hours_frequency = contents.reduce(Hash.new) do |count, row|
        hour = Time.strptime(row[:regdate], "%y/%d/%m %H:%M").hour
        (count[hour] = 0) unless !count[hour].nil?
        count[hour] += 1
        count
    end
    # sort and return the result
    hours_frequency.sort_by { |hour, frequency| frequency }.reverse.to_h
end

def save_thank_you_letter(id, form_letter)
    Dir.mkdir('output') unless Dir.exist?('output')

    filename = "output/thanks_#{id}.html"

    File.open(filename, 'w') do |file|
        file.puts form_letter
    end
end

puts 'Event Manager Initialized!'

contents = CSV.open(
    'event_attendees.csv',
    headers: true,
    header_converters: :symbol # access individual columns by their names, from inside the rows.
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

contents.each do |row|
    id = row[0]
    name = row[:first_name]

    zipcode = clean_zipcode(row[:zipcode])

    phone = clean_phone_number(row[:homephone])

    legislators = legislators_by_zipcode(zipcode)

    form_letter = erb_template.result(binding)
    
    save_thank_you_letter(id, form_letter)
end

peak_registration_hours = find_peak_registration_hours(contents)

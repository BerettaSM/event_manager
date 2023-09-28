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

def extract_registration_dates(contents)
    contents.collect { |row| Time.strptime(row[:regdate], "%y/%d/%m %H:%M") }
end

def get_sorted_count(array)
    # count
    count = array.reduce(Hash.new) do |acc, element|
        (acc[element] = 0) unless !acc[element].nil?
        acc[element] += 1
        acc
    end
    # sort
    sorted_count = count.sort_by { |element, frequency| frequency }.reverse
    # return
    sorted_count.to_h
end

def find_peak_hours(registration_dates)
    # get hours from dates
    hours = registration_dates.collect { |date| date.hour }
    # return sorted count of hours
    get_sorted_count(hours)
end

def find_peak_week_days(registration_dates)
    # get week days from dates
    week_days = registration_dates.collect { |date| date.strftime("%A") }
    # return sorted count of hours
    get_sorted_count(week_days)
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

registration_dates = extract_registration_dates(contents)
peak_hours = find_peak_hours(registration_dates)
peak_week_days = find_peak_week_days(registration_dates)

puts "Most active hour is: #{peak_hours.to_a.dig(0, 0)}:00"
puts "Most active day is: #{peak_week_days.to_a.dig(0, 0)}"

require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_number(number)
  if 10 < number.length > 11
    "Invalid Number"
  elsif number.length == 11
    if number[0] == 1
      number[1..11]
    else
      "Invalid Number"
    end
  else
    number
  end

end

def check_times(times)
  times.max_by { |time| times.count(time)}
end


def legislators_by_zipcode(zipcode)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    legislators = civic_info.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    )
    legislators = legislators.officials
  rescue
    "You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials"
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')
  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts "Event Manager Initialized!"

contents = CSV.open('event_attendees.csv', 
  headers: true,
  header_converters: :symbol
)
contents_size = CSV.read('event_attendees.csv').length
template_letter = File.read('form_letter.html.erb')
erb_template = ERB.new template_letter
weekdays = {0=>"sunday",1=>"monday",2=>"tuesday",3=>"wednesday",4=>"thursday",5=>"friday",6=>"saturday"}
hours = []
days = []

puts contents
contents.each_with_index do |row, index|
  reg_date = row[:regdate]
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  form_letter = erb_template.result(binding)

  converted_reg_date = DateTime.strptime(reg_date, "%m/%d/%y %H:%M")
  hours[index] = converted_reg_date.hour
  days[index] = converted_reg_date.wday
  save_thank_you_letter(id, form_letter)
end

puts "Most Active Hour is: #{check_times(hours)}:00"
puts "Most active Day is #{weekdays[check_times(days)].capitalize}" 
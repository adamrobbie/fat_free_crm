require 'csv'

namespace :rthreaded do
  namespace :account_import do
    desc "Setup account.csv"
    task copy_account_csv: :environment do

     fields_to_insert = %w{ Name Company Email Phone Feedback }
     rows_to_insert = []

     CSV.foreach("customers.csv", headers: true) do |row|
        row_to_insert = row.to_hash.select { |k, v| fields_to_insert.include?(k) }
        rows_to_insert << row_to_insert
				puts row.inspect
				if(account = Account.find_by(name: row["Company"]))
					fname, lname = row["Name"].split(" ")
					account.contacts << Contact.new(
						first_name: fname,
						last_name: lname,
						email: row["Email"]
					)
					account.add_comment_by_user("Products Orders: "+ row["Products Ordered"], User.first)
					if !row["Feedback"].nil?
						account.add_comment_by_user(row["Feedback"], User.first)
					end
					account.save
				else
					account = Account.new(
						name: row["Company"],
						phone: row["Phone"],
						email: row["Email"],
						category: "customer",
						rating: 5
					)
					if account.save
						fname, lname = row["Name"].split(" ")
						account.contacts << Contact.new(
							first_name: fname,
							last_name: lname,
							email: row["Email"]
						)
						account.add_comment_by_user("Products Orders: "+ row["Products Ordered"], User.first)
						if !row["Feedback"].nil?
							account.add_comment_by_user(row["Feedback"], User.first)
						end
						account.save
					end
				end
      end
    end
  end

	namespace :leads_import do
		desc "Setup lead.csv"
		task copy_leads_csv: :environment do

		 fields_to_insert = %w{ Name Company Title Email Phone Feedback data_of_last_contact form_of_contact Purpose Status_Chain Notes_from_follow_up }
		 rows_to_insert = []

		 CSV.foreach("leads.csv", headers: true) do |row|
				row_to_insert = row.to_hash.select { |k, v| fields_to_insert.include?(k) }
				rows_to_insert << row_to_insert
				puts row.inspect
				fname, lname = if row["Name"].present?
					row["Name"].split(" ")
				else
					["Not Given", "Not Given"]
				end
				lead = Lead.new(
					first_name: fname,
					last_name: lname,
					company: row["Company"],
					title: truncate(row["Title"]),
					email: row["Email"],
					phone: truncate_phone(row["Phone"])
				)
				if lead.save
					if row["purpose"].present?
						comment = "Purpose: " + row["purpose"]
						lead.add_comment_by_user(comment, User.first)
					end
					if row["date of last contact"].present?
						comment = "Date of Last contact: " + row["date of last contact"]
						lead.add_comment_by_user(comment, User.first)
					end
					if row["Form Of Contact"].present?
						comment = "Form of contact: " + row["Form Of Contact"]
						lead.add_comment_by_user(comment, User.first)
					end
					if row["Status Chain"].present?
						comment = "Status Chain: " + row["Status Chain"]
						lead.add_comment_by_user(comment, User.first)
					end
					if row["Notes from Follow ups"].present?
						comment = "Notes from Follow up: " + row["Notes from Follow ups"]
						lead.add_comment_by_user(comment, User.first)
					end
					if row["Phone"].present? and row["Phone"].length > 32
						comment = "Additional Phone Numbers:" + row["Phone"]
						lead.add_comment_by_user(comment, User.first)
					end
				end
			end
		end
	end

	namespace :oppurtunities_import do
		desc "Setup oppurtunities.csv"
		task copy_oppurtunities_csv: :environment do

		 fields_to_insert = %w{ Company Title Email ContactDate Status Note1 Note2 Note3 }
		 rows_to_insert = []

		 CSV.foreach("opportunities.csv", headers: true) do |row|
				row_to_insert = row.to_hash.select { |k, v| fields_to_insert.include?(k) }
				rows_to_insert << row_to_insert
				puts row.inspect
				opp = Opportunity.new(
					name: row["Contact"],
					stage: "Meeting",
					closes_on: row["ContactDate"]
				)
				account = find_account(row["Company"])
				opp.account_opportunity = AccountOpportunity.new(account: account, opportunity: opp)
				opp.account = account
				opp.save
				fname,lname = row["Contact"].split(" ")
				opp.contacts << Contact.create(first_name: fname, last_name: lname, email: row["Email"], phone: row["Phone"])

				if opp
					if row["Status"].present?
						opp.add_comment_by_user(row["Status"], User.first)
					end
					if row["Note1"].present?
						opp.add_comment_by_user(row["Note1"], User.first)
					end
					if row["Note2"].present?
						opp.add_comment_by_user(row["Note2"], User.first)
					end
					if row["Note3"].present?
						opp.add_comment_by_user(row["Note3"], User.first)
					end
				end
			end
		end
	end

	def truncate(string)
		if string.present?
			string.truncate(64)
		else
			string
		end
	end
	def find_account(name)
		if account = Account.find_by(name: name)
			account
		else
			Account.create(name: name)
		end
	end

	def truncate_phone(string)
		if string.present? and string.length > 32
			string.split(" ").first
		else
			string
		end
	end
end

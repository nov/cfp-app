require "rails_helper"

feature "Event Dashboard" do
  let(:event) { create(:event, name: "My Event") }
  let(:organizer_user) { create(:user) }
  let!(:event_staff_teammate) { create(:event_teammate,
                                       event: event,
                                       user: organizer_user,
                                       role: "organizer")
  }

  let(:reviewer_user) { create(:user) }
  let!(:reviewer_event_teammate) { create(:event_teammate,
                                      event: event,
                                      user: reviewer_user,
                                      role: "reviewer")
  }

  context "As an organizer" do
    before :each do
      logout
      login_as(organizer_user)
      visit event_staff_path(event)
    end

    it "cannot create new events" do
      # pending "This fails because it sends them to login and then Devise sends to events path and changes flash"
      visit new_admin_event_path
      expect(page.current_path).to eq(events_path)
      #Losing the flash on redirect here.
      # expect(page).to have_text("You must be signed in as an administrator")
    end

    it "can edit events" do
      visit event_staff_edit_path(event)
      fill_in "Name", with: "Blef"
      click_button 'Save'
      expect(page).to have_text("Blef")
    end

    it "can change event status" do
      visit event_staff_info_path(event)

      within('.page-header') do
        expect(page).to have_content("Event Status: Draft")
      end

      click_link("Change Status")
      select('open', :from => 'event[state]')
      click_button("Update Status")

      within('.page-header') do
        expect(page).to have_content("Event Status: Open")
      end
    end

    it "cannot delete events" do
      visit event_staff_url(event)
      expect(page).not_to have_link('Delete Event')
    end

# move all the invite/team management specs to other spec file
# I don't like the language used below.  Match the checklist in the card instead
# -- how would you explain this to another dev or new organizer
    it "can promote a user" do
      pending "This fails because add/invite new teammate is no longer on this page. Change path once new card is complete"
      user = create(:user)
      visit event_staff_path(event)
      click_link 'Add/Invite Staff'

      form = find('#new_event_teammate')
      form.fill_in :email, with: user.email
      form.select 'organizer', from: 'Role'
      form.click_button('Save')

      expect(user).to be_organizer_for_event(event)
    end

    it "can promote an event teammate" do
      pending "This fails because the event teammates section is no longer on this page. Change path once new card is complete"
      visit event_staff_path(event)

      form = find('tr', text: reviewer_user.email).find('form')
      form.select 'organizer', from: 'Role'
      form.click_button('Save')

      expect(reviewer_user).to be_organizer_for_event(event)
    end

    it "can remove a event teammate" do
      pending "This fails because add/invite new teammate is no longer on this page. Change path once new card is complete"
      visit event_staff_path(event)

      row = find('tr', text: reviewer_user.email)
      row.click_link 'Remove'

      expect(reviewer_user).to_not be_reviewer_for_event(event)
    end

    it "can invite a new event teammate" do
      pending "This fails because role is not getting set for some reason and is an empty string in the db"
      visit event_staff_team_index_path(event)

      click_on "Invite new event teammate"
      fill_in "Email", with: "harrypotter@hogwarts.edu"
      select "program team", from: "Role"
      click_button("Invite")

      email = ActionMailer::Base.deliveries.last
      expect(email.to).to eq([ "harrypotter@hogwarts.edu" ])
      expect(page).to have_text("Event teammate invitation successfully sent")
    end
  end

  context "As a reviewer" do
    before :each do
      logout
      login_as(reviewer_user)
      visit event_staff_path(event)
    end

    it "cannot view buttons to edit event or change status" do
      visit event_staff_info_path(event)

      within(".page-header") do
        expect(page).to have_content("Event Status: Draft")
      end

      expect(page).to_not have_link("Change Status")
      expect(page).to_not have_css(".btn-nav")
    end

  end
end

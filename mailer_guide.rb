  begin
    do stuff

  rescue => error
    alert_emails = JSON.parse(File.read('./alert.json'))

    message = "From: ED Dashboard <#{alert_emails['from']}>"
    message = [message, "To: Test User <john.lackey@jefferson.edu>"].join($/)
    message = [message, "Subject: PROBLEM WITH EPIC DATA FEED!"].join($/)
    message = [message, ""].join($/)
    message = [message, "ERROR: #{error.inspect}."].join($/)
    message = [message, ""].join($/)

    Net::SMTP.start('smtp.jefferson.edu') do |smtp|
      smtp.send_message message, alert_emails['from'], alert_emails['waitingroom']
    end
  end

  alert.json:
  { "waitingroom": ["luke.kedziora@jefferson.edu"],
    "intake":      ["noreply@jefferson.edu"],
    "from":        "noreply@lxk051.833chestnut.tju.edu" }
with open('udo.csv') as f:
    arquivo = f.read().split("\n")
    for x in arquivo:
        x = x.split(";")
        university_id = x[0].strip()
        admin_user_id = x[1].strip()
        start_date = x[2].strip()
        end_date = x[3].strip()
        grad_presencial = x[4].strip()
        grad_ead = x[5].strip()
        pos = x[6].strip()

        if end_date == "6/9/17":
            end_date = "null"
        else:
            end_date = end_date.split("/")
            end_date = "'20" + end_date[2] + "-" + end_date[0].zfill(2) + "-" + end_date[1].zfill(2) + "'"

        start_date = start_date.split("/")
        start_date = "20" + start_date[2] + "-" + start_date[0].zfill(2) + "-" + start_date[1].zfill(2)

        if grad_presencial == "1":
            print "insert into university_deal_owners(admin_user_id, university_id, product_line_id, start_date, end_date) values(" + admin_user_id + ", " + university_id + ", 4, '"+ start_date + "', "+ end_date + ");"

        if grad_ead == "1":
            print "insert into university_deal_owners(admin_user_id, university_id, product_line_id, start_date, end_date) values(" + admin_user_id + ", " + university_id + ", 2, '"+ start_date + "', "+ end_date + ");"

        if pos == "1":
            print "insert into university_deal_owners(admin_user_id, university_id, product_line_id, start_date, end_date) values(" + admin_user_id + ", " + university_id + ", 8, '"+ start_date + "', "+ end_date + ");"

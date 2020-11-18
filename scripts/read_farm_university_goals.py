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
        esperado_grad_presencial = x[7].strip()
        esperado_grad_ead = x[8].strip()
        esperado_grad_pos = x[9].strip()

        if grad_presencial == "1":
            print "insert into farm_university_goals(capture_period_id, university_id, product_line_id, goal, inserted_at, updated_at) values(2, " + university_id + ", 4, " + esperado_grad_presencial + ", '2017-06-07', '2017-06-07');"

        if grad_ead == "1":
            print "insert into farm_university_goals(capture_period_id, university_id, product_line_id, goal, inserted_at, updated_at) values(2, " + university_id + ", 2, " + esperado_grad_ead + ", '2017-06-07', '2017-06-07');"

        if pos == "1":
            print "insert into farm_university_goals(capture_period_id, university_id, product_line_id, goal, inserted_at, updated_at) values(2, " + university_id + ", 8, " + esperado_grad_pos + ", '2017-06-07', '2017-06-07');"

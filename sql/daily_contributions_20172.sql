delete from capture_periods where id = 2;
insert into capture_periods values (2, '2017.2', '2017-04-01 03:00:00', '2017-09-30 23:59:59', '2017-01-31 23:59:59', '2017-01-31 23:59:59');
delete from daily_contributions where capture_period_id = 2;

insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-04-1 00:00:00',  0.0004500000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-04-2 00:00:00',  0.0003800000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-04-3 00:00:00',  0.0034600000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-04-4 00:00:00',  0.0025000000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-04-5 00:00:00',  0.0024300000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-04-6 00:00:00',  0.0025000000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-04-7 00:00:00',  0.0028700000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-04-8 00:00:00',  0.0004200000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-04-9 00:00:00',  0.0003200000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-04-10 00:00:00', 0.0030600000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-04-11 00:00:00', 0.0025000000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-04-12 00:00:00', 0.0017700000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-04-13 00:00:00', 0.0016200000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-04-14 00:00:00', 0.0021000000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-04-15 00:00:00', 0.0004300000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-04-16 00:00:00', 0.0002600000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-04-17 00:00:00', 0.0023100000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-04-18 00:00:00', 0.0016500000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-04-19 00:00:00', 0.0022800000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-04-20 00:00:00', 0.0004400000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-04-21 00:00:00', 0.0017500000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-04-22 00:00:00', 0.0001100000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-04-23 00:00:00', 0.0002100000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-04-24 00:00:00', 0.0028400000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-04-25 00:00:00', 0.0022400000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-04-26 00:00:00', 0.0024200000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-04-27 00:00:00', 0.0022100000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-04-28 00:00:00', 0.0027700000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-04-29 00:00:00', 0.0005100000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-04-30 00:00:00', 0.0003700000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-05-1 00:00:00',  0.0028000000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-05-2 00:00:00',  0.0023600000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-05-3 00:00:00',  0.0025100000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-05-4 00:00:00',  0.0028400000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-05-5 00:00:00',  0.0035500000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-05-6 00:00:00',  0.0005000000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-05-7 00:00:00',  0.0005400000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-05-8 00:00:00',  0.0040300000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-05-9 00:00:00',  0.0035900000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-05-10 00:00:00', 0.0044500000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-05-11 00:00:00', 0.0038500000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-05-12 00:00:00', 0.0027300000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-05-13 00:00:00', 0.0007800000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-05-14 00:00:00', 0.0008400000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-05-15 00:00:00', 0.0035000000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-05-16 00:00:00', 0.0036900000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-05-17 00:00:00', 0.0032400000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-05-18 00:00:00', 0.0037500000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-05-19 00:00:00', 0.0044100000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-05-20 00:00:00', 0.0007800000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-05-21 00:00:00', 0.0007500000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-05-22 00:00:00', 0.0054500000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-05-23 00:00:00', 0.0041500000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-05-24 00:00:00', 0.0029300000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-05-25 00:00:00', 0.0004500000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-05-26 00:00:00', 0.0019200000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-05-27 00:00:00', 0.0002000000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-05-28 00:00:00', 0.0002400000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-05-29 00:00:00', 0.0024400000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-05-30 00:00:00', 0.0021800000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-05-31 00:00:00', 0.0023800000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-06-1 00:00:00',  0.0043900000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-06-2 00:00:00',  0.0032800000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-06-3 00:00:00',  0.0004800000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-06-4 00:00:00',  0.0008700000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-06-5 00:00:00',  0.0042900000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-06-6 00:00:00',  0.0062600000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-06-7 00:00:00',  0.0067400000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-06-8 00:00:00',  0.0071400000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-06-9 00:00:00',  0.0058700000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-06-10 00:00:00', 0.0009400000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-06-11 00:00:00', 0.0005900000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-06-12 00:00:00', 0.0062500000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-06-13 00:00:00', 0.0069900000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-06-14 00:00:00', 0.0078100000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-06-15 00:00:00', 0.0069400000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-06-16 00:00:00', 0.0053200000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-06-17 00:00:00', 0.0014500000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-06-18 00:00:00', 0.0009400000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-06-19 00:00:00', 0.0085100000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-06-20 00:00:00', 0.0059400000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-06-21 00:00:00', 0.0068000000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-06-22 00:00:00', 0.0063900000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-06-23 00:00:00', 0.0052400000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-06-24 00:00:00', 0.0008700000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-06-25 00:00:00', 0.0006400000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-06-26 00:00:00', 0.0084800000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-06-27 00:00:00', 0.0082100000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-06-28 00:00:00', 0.0084800000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-06-29 00:00:00', 0.0083400000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-06-30 00:00:00', 0.0083900000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-07-1 00:00:00',  0.0012200000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-07-2 00:00:00',  0.0011200000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-07-3 00:00:00',  0.0136200000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-07-4 00:00:00',  0.0103400000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-07-5 00:00:00',  0.0106000000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-07-6 00:00:00',  0.0107300000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-07-7 00:00:00',  0.0081800000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-07-8 00:00:00',  0.0013000000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-07-9 00:00:00',  0.0013600000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-07-10 00:00:00', 0.0124400000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-07-11 00:00:00', 0.0099200000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-07-12 00:00:00', 0.0109400000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-07-13 00:00:00', 0.0094400000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-07-14 00:00:00', 0.0087300000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-07-15 00:00:00', 0.0015000000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-07-16 00:00:00', 0.0011700000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-07-17 00:00:00', 0.0116700000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-07-18 00:00:00', 0.0095600000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-07-19 00:00:00', 0.0108300000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-07-20 00:00:00', 0.0107300000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-07-21 00:00:00', 0.0089300000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-07-22 00:00:00', 0.0015600000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-07-23 00:00:00', 0.0008600000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-07-24 00:00:00', 0.0141100000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-07-25 00:00:00', 0.0124300000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-07-26 00:00:00', 0.0138700000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-07-27 00:00:00', 0.0105700000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-07-28 00:00:00', 0.0125700000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-07-29 00:00:00', 0.0014900000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-07-30 00:00:00', 0.0010300000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-07-31 00:00:00', 0.0197300000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-08-1 00:00:00',  0.0227200000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-08-2 00:00:00',  0.0177800000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-08-3 00:00:00',  0.0184000000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-08-4 00:00:00',  0.0164800000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-08-5 00:00:00',  0.0024200000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-08-6 00:00:00',  0.0014800000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-08-7 00:00:00',  0.0187300000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-08-8 00:00:00',  0.0157600000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-08-9 00:00:00',  0.0125300000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-08-10 00:00:00', 0.0128900000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-08-11 00:00:00', 0.0111800000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-08-12 00:00:00', 0.0014400000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-08-13 00:00:00', 0.0008000000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-08-14 00:00:00', 0.0109100000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-08-15 00:00:00', 0.0149900000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-08-16 00:00:00', 0.0118000000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-08-17 00:00:00', 0.0112200000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-08-18 00:00:00', 0.0119600000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-08-19 00:00:00', 0.0014400000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-08-20 00:00:00', 0.0010000000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-08-21 00:00:00', 0.0166700000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-08-22 00:00:00', 0.0159500000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-08-23 00:00:00', 0.0141500000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-08-24 00:00:00', 0.0130600000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-08-25 00:00:00', 0.0114400000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-08-26 00:00:00', 0.0022600000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-08-27 00:00:00', 0.0013700000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-08-28 00:00:00', 0.0121200000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-08-29 00:00:00', 0.0098200000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-08-30 00:00:00', 0.0103000000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-08-31 00:00:00', 0.0097100000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-09-1 00:00:00',  0.0127600000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-09-2 00:00:00',  0.0026900000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-09-3 00:00:00',  0.0020200000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-09-4 00:00:00',  0.0116700000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-09-5 00:00:00',  0.0108900000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-09-6 00:00:00',  0.0022500000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-09-7 00:00:00',  0.0094100000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-09-8 00:00:00',  0.0067100000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-09-9 00:00:00',  0.0008200000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-09-10 00:00:00', 0.0014100000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-09-11 00:00:00', 0.0084300000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-09-12 00:00:00', 0.0064600000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-09-13 00:00:00', 0.0044100000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-09-14 00:00:00', 0.0053800000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-09-15 00:00:00', 0.0040500000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-09-16 00:00:00', 0.0010000000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-09-17 00:00:00', 0.0003700000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-09-18 00:00:00', 0.0043400000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-09-19 00:00:00', 0.0051000000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-09-20 00:00:00', 0.0043100000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-09-21 00:00:00', 0.0050800000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-09-22 00:00:00', 0.0035400000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-09-23 00:00:00', 0.0013200000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-09-24 00:00:00', 0.0002900000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-09-25 00:00:00', 0.0050900000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-09-26 00:00:00', 0.0026000000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-09-27 00:00:00', 0.0034500000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-09-28 00:00:00', 0.0037500000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-09-29 00:00:00', 0.0046200000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-09-30 00:00:00', 0.0005900000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 2)
	RETURNING id;

insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-04-1 00:00:00',  0.0004500000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-04-2 00:00:00',  0.0003800000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-04-3 00:00:00',  0.0034600000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-04-4 00:00:00',  0.0025000000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-04-5 00:00:00',  0.0024300000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-04-6 00:00:00',  0.0025000000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-04-7 00:00:00',  0.0028700000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-04-8 00:00:00',  0.0004200000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-04-9 00:00:00',  0.0003200000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-04-10 00:00:00', 0.0030600000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-04-11 00:00:00', 0.0025000000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-04-12 00:00:00', 0.0017700000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-04-13 00:00:00', 0.0016200000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-04-14 00:00:00', 0.0021000000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-04-15 00:00:00', 0.0004300000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-04-16 00:00:00', 0.0002600000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-04-17 00:00:00', 0.0023100000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-04-18 00:00:00', 0.0016500000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-04-19 00:00:00', 0.0022800000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-04-20 00:00:00', 0.0004400000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-04-21 00:00:00', 0.0017500000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-04-22 00:00:00', 0.0001100000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-04-23 00:00:00', 0.0002100000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-04-24 00:00:00', 0.0028400000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-04-25 00:00:00', 0.0022400000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-04-26 00:00:00', 0.0024200000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-04-27 00:00:00', 0.0022100000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-04-28 00:00:00', 0.0027700000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-04-29 00:00:00', 0.0005100000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-04-30 00:00:00', 0.0003700000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-05-1 00:00:00',  0.0028000000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-05-2 00:00:00',  0.0023600000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-05-3 00:00:00',  0.0025100000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-05-4 00:00:00',  0.0028400000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-05-5 00:00:00',  0.0035500000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-05-6 00:00:00',  0.0005000000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-05-7 00:00:00',  0.0005400000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-05-8 00:00:00',  0.0040300000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-05-9 00:00:00',  0.0035900000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-05-10 00:00:00', 0.0044500000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-05-11 00:00:00', 0.0038500000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-05-12 00:00:00', 0.0027300000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-05-13 00:00:00', 0.0007800000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-05-14 00:00:00', 0.0008400000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-05-15 00:00:00', 0.0035000000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-05-16 00:00:00', 0.0036900000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-05-17 00:00:00', 0.0032400000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-05-18 00:00:00', 0.0037500000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-05-19 00:00:00', 0.0044100000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-05-20 00:00:00', 0.0007800000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-05-21 00:00:00', 0.0007500000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-05-22 00:00:00', 0.0054500000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-05-23 00:00:00', 0.0041500000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-05-24 00:00:00', 0.0029300000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-05-25 00:00:00', 0.0004500000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-05-26 00:00:00', 0.0019200000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-05-27 00:00:00', 0.0002000000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-05-28 00:00:00', 0.0002400000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-05-29 00:00:00', 0.0024400000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-05-30 00:00:00', 0.0021800000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-05-31 00:00:00', 0.0023800000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-06-1 00:00:00',  0.0043900000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-06-2 00:00:00',  0.0032800000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-06-3 00:00:00',  0.0004800000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-06-4 00:00:00',  0.0008700000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-06-5 00:00:00',  0.0042900000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-06-6 00:00:00',  0.0062600000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-06-7 00:00:00',  0.0067400000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-06-8 00:00:00',  0.0071400000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-06-9 00:00:00',  0.0058700000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-06-10 00:00:00', 0.0009400000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-06-11 00:00:00', 0.0005900000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-06-12 00:00:00', 0.0062500000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-06-13 00:00:00', 0.0069900000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-06-14 00:00:00', 0.0078100000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-06-15 00:00:00', 0.0069400000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-06-16 00:00:00', 0.0053200000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-06-17 00:00:00', 0.0014500000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-06-18 00:00:00', 0.0009400000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-06-19 00:00:00', 0.0085100000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-06-20 00:00:00', 0.0059400000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-06-21 00:00:00', 0.0068000000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-06-22 00:00:00', 0.0063900000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-06-23 00:00:00', 0.0052400000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-06-24 00:00:00', 0.0008700000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-06-25 00:00:00', 0.0006400000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-06-26 00:00:00', 0.0084800000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-06-27 00:00:00', 0.0082100000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-06-28 00:00:00', 0.0084800000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-06-29 00:00:00', 0.0083400000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-06-30 00:00:00', 0.0083900000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-07-1 00:00:00',  0.0012200000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-07-2 00:00:00',  0.0011200000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-07-3 00:00:00',  0.0136200000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-07-4 00:00:00',  0.0103400000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-07-5 00:00:00',  0.0106000000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-07-6 00:00:00',  0.0107300000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-07-7 00:00:00',  0.0081800000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-07-8 00:00:00',  0.0013000000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-07-9 00:00:00',  0.0013600000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-07-10 00:00:00', 0.0124400000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-07-11 00:00:00', 0.0099200000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-07-12 00:00:00', 0.0109400000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-07-13 00:00:00', 0.0094400000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-07-14 00:00:00', 0.0087300000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-07-15 00:00:00', 0.0015000000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-07-16 00:00:00', 0.0011700000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-07-17 00:00:00', 0.0116700000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-07-18 00:00:00', 0.0095600000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-07-19 00:00:00', 0.0108300000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-07-20 00:00:00', 0.0107300000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-07-21 00:00:00', 0.0089300000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-07-22 00:00:00', 0.0015600000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-07-23 00:00:00', 0.0008600000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-07-24 00:00:00', 0.0141100000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-07-25 00:00:00', 0.0124300000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-07-26 00:00:00', 0.0138700000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-07-27 00:00:00', 0.0105700000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-07-28 00:00:00', 0.0125700000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-07-29 00:00:00', 0.0014900000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-07-30 00:00:00', 0.0010300000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-07-31 00:00:00', 0.0197300000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-08-1 00:00:00',  0.0227200000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-08-2 00:00:00',  0.0177800000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-08-3 00:00:00',  0.0184000000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-08-4 00:00:00',  0.0164800000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-08-5 00:00:00',  0.0024200000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-08-6 00:00:00',  0.0014800000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-08-7 00:00:00',  0.0187300000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-08-8 00:00:00',  0.0157600000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-08-9 00:00:00',  0.0125300000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-08-10 00:00:00', 0.0128900000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-08-11 00:00:00', 0.0111800000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-08-12 00:00:00', 0.0014400000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-08-13 00:00:00', 0.0008000000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-08-14 00:00:00', 0.0109100000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-08-15 00:00:00', 0.0149900000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-08-16 00:00:00', 0.0118000000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-08-17 00:00:00', 0.0112200000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-08-18 00:00:00', 0.0119600000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-08-19 00:00:00', 0.0014400000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-08-20 00:00:00', 0.0010000000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-08-21 00:00:00', 0.0166700000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-08-22 00:00:00', 0.0159500000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-08-23 00:00:00', 0.0141500000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-08-24 00:00:00', 0.0130600000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-08-25 00:00:00', 0.0114400000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-08-26 00:00:00', 0.0022600000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-08-27 00:00:00', 0.0013700000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-08-28 00:00:00', 0.0121200000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-08-29 00:00:00', 0.0098200000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-08-30 00:00:00', 0.0103000000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-08-31 00:00:00', 0.0097100000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-09-1 00:00:00',  0.0127600000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-09-2 00:00:00',  0.0026900000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-09-3 00:00:00',  0.0020200000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-09-4 00:00:00',  0.0116700000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-09-5 00:00:00',  0.0108900000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-09-6 00:00:00',  0.0022500000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-09-7 00:00:00',  0.0094100000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-09-8 00:00:00',  0.0067100000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-09-9 00:00:00',  0.0008200000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-09-10 00:00:00', 0.0014100000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-09-11 00:00:00', 0.0084300000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-09-12 00:00:00', 0.0064600000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-09-13 00:00:00', 0.0044100000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-09-14 00:00:00', 0.0053800000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-09-15 00:00:00', 0.0040500000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-09-16 00:00:00', 0.0010000000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-09-17 00:00:00', 0.0003700000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-09-18 00:00:00', 0.0043400000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-09-19 00:00:00', 0.0051000000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-09-20 00:00:00', 0.0043100000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-09-21 00:00:00', 0.0050800000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-09-22 00:00:00', 0.0035400000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-09-23 00:00:00', 0.0013200000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-09-24 00:00:00', 0.0002900000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-09-25 00:00:00', 0.0050900000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-09-26 00:00:00', 0.0026000000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-09-27 00:00:00', 0.0034500000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-09-28 00:00:00', 0.0037500000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-09-29 00:00:00', 0.0046200000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-09-30 00:00:00', 0.0005900000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 4)
	RETURNING id;





insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-4-1 00:00:00',  0.00333371349264866999, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-4-2 00:00:00',  0.00049200517005656703, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-4-3 00:00:00',  0.01012660179631039853, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-4-4 00:00:00',  0.00653394219800584007, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-4-5 00:00:00',  0.00797324655317900935, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-4-6 00:00:00',  0.00660963530109147032, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-4-7 00:00:00',  0.00460161926466485984, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-4-8 00:00:00',  0.00113539654628439001, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-4-9 00:00:00',  0.00242672088492515989, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-4-10 00:00:00', 0.01259147200519069969, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-4-11 00:00:00', 0.00578753250847848042, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-4-12 00:00:00', 0.00528614139363929939, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-4-13 00:00:00', 0.00519178994064306999, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-4-14 00:00:00', 0.01339082902032650083, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-4-15 00:00:00', 0.00056769827314219294, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-4-16 00:00:00', 0.00060668022123128997, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-4-17 00:00:00', 0.00577462683440238978, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-4-18 00:00:00', 0.00504838935684735063, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-4-19 00:00:00', 0.00434856877226920055, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-4-20 00:00:00', 0.00000378465515428129, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-4-21 00:00:00', 0.00230284912172552987, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-4-22 00:00:00', 0.00000378465515428129, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-4-23 00:00:00', 0.00000000000000000000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-4-24 00:00:00', 0.00488621688348640001, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-4-25 00:00:00', 0.00126872994736971991, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-4-26 00:00:00', 0.00337349021832016992, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-4-27 00:00:00', 0.00356139834673022994, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-4-28 00:00:00', 0.00356211743120954990, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-4-29 00:00:00', 0.00000378465515428128, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-4-30 00:00:00', 0.00121336044246257995, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-5-1 00:00:00',  0.00940998565487762874, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-5-2 00:00:00',  0.00353935738635529013, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-5-3 00:00:00',  0.00518153549069413043, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-5-4 00:00:00',  0.00395384484972490045, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-5-5 00:00:00',  0.00184426285266023012, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-5-6 00:00:00',  0.00000294799049338272, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-5-7 00:00:00',  0.00000294799049338272, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-5-8 00:00:00',  0.00380603260638668998, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-5-9 00:00:00',  0.00640250471333845064, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-5-10 00:00:00', 0.00380906903659486993, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-5-11 00:00:00', 0.00317457304270411019, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-5-12 00:00:00', 0.00268532454042230955, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-5-13 00:00:00', 0.00000294799049338272, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-5-14 00:00:00', 0.00047256287608924899, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-5-15 00:00:00', 0.00751742961976171933, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-5-16 00:00:00', 0.00390691284107023973, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-5-17 00:00:00', 0.00492314177094571939, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-5-18 00:00:00', 0.00138732432618590999, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-5-19 00:00:00', 0.00292617536373168024, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-5-20 00:00:00', 0.00141674527130985985, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-5-21 00:00:00', 0.00047256287608924899, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-5-22 00:00:00', 0.00356739277594736014, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-5-23 00:00:00', 0.00255564243861841015, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-5-24 00:00:00', 0.00465892535227620946, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-5-25 00:00:00', 0.00000294799049338272, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-5-26 00:00:00', 0.00462669419993457041, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-5-27 00:00:00', 0.00091476145009665596, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-5-28 00:00:00', 0.00000294799049338272, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-5-29 00:00:00', 0.00595406601573403998, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-5-30 00:00:00', 0.00597166551897954003, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-5-31 00:00:00', 0.00181566734487441004, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-6-1 00:00:00',  0.00149553145737544007, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-6-2 00:00:00',  0.00194398634255575002, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-6-3 00:00:00',  0.00000266080802430297, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-6-4 00:00:00',  0.00039912120364544600, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-6-5 00:00:00',  0.00344172627059134966, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-6-6 00:00:00',  0.00476268459123845023, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-6-7 00:00:00',  0.00367389275094520034, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-6-8 00:00:00',  0.00519331188567406007, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-6-9 00:00:00',  0.00472940638534167027, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-6-10 00:00:00', 0.00104960894134679007, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-6-11 00:00:00', 0.00000266080802430301, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-6-12 00:00:00', 0.00577932512895404024, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-6-13 00:00:00', 0.00241308679724037013, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-6-14 00:00:00', 0.00260493105579260968, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-6-15 00:00:00', 0.00501001646310393969, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-6-16 00:00:00', 0.00491472528552952970, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-6-17 00:00:00', 0.00282160720889831039, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-6-18 00:00:00', 0.00000266080802430310, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-6-19 00:00:00', 0.00662802825184732967, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-6-20 00:00:00', 0.00285390073884423008, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-6-21 00:00:00', 0.00117155377310059990, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-6-22 00:00:00', 0.00114414745045028003, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-6-23 00:00:00', 0.00296951497128260028, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-6-24 00:00:00', 0.00072134505538853607, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-6-25 00:00:00', 0.00039912120364544600, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-6-26 00:00:00', 0.00415466547338739015, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-6-27 00:00:00', 0.00788127918655272958, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-6-28 00:00:00', 0.00805884903505360052, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-6-29 00:00:00', 0.00756752215389694914, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-6-30 00:00:00', 0.00318221996474538039, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-7-1 00:00:00',  0.00137052187073841017, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-7-2 00:00:00',  0.00000193609350559192, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-7-3 00:00:00',  0.00761633439469052050, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-7-4 00:00:00',  0.00353896428382286009, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-7-5 00:00:00',  0.00745610758513398988, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-7-6 00:00:00',  0.00546226740147956989, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-7-7 00:00:00',  0.00376287432341503025, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-7-8 00:00:00',  0.00165195873818522001, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-7-9 00:00:00',  0.00029041402583878902, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-7-10 00:00:00', 0.00837065382228479107, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-7-11 00:00:00', 0.00757936043494185970, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-7-12 00:00:00', 0.00725930105492251024, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-7-13 00:00:00', 0.00796872429079963085, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-7-14 00:00:00', 0.00293023879884326969, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-7-15 00:00:00', 0.00207613808670837003, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-7-16 00:00:00', 0.00101451299693016989, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-7-17 00:00:00', 0.01313080540052729943, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-7-18 00:00:00', 0.00957665328850854959, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-7-19 00:00:00', 0.00804881168066094027, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-7-20 00:00:00', 0.00930227102257730892, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-7-21 00:00:00', 0.00736300709377457965, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-7-22 00:00:00', 0.00202224966659076983, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-7-23 00:00:00', 0.00000193609350559196, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-7-24 00:00:00', 0.01038944406343679863, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-7-25 00:00:00', 0.00994404729781091928, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-7-26 00:00:00', 0.01082647389239759818, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-7-27 00:00:00', 0.00784063359140309973, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-7-28 00:00:00', 0.00673512664574525948, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-7-29 00:00:00', 0.00153340570845269001, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-7-30 00:00:00', 0.00079437916534436798, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-7-31 00:00:00', 0.01463600117622060152, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-8-1 00:00:00',  0.00939535744993568941, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-8-2 00:00:00',  0.00976093143770740898, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-8-3 00:00:00',  0.01528278574443830105, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-8-4 00:00:00',  0.00835230275423214964, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-8-5 00:00:00',  0.00166736955322434994, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-8-6 00:00:00',  0.00096902401229453201, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-8-7 00:00:00',  0.01416462814522690024, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-8-8 00:00:00',  0.01385684055591970137, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-8-9 00:00:00',  0.00816165907879821961, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-8-10 00:00:00', 0.01080063403828149943, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-8-11 00:00:00', 0.01305495787789370116, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-8-12 00:00:00', 0.00224277693055327998, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-8-13 00:00:00', 0.00149722088143507993, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-8-14 00:00:00', 0.01526888939924459995, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-8-15 00:00:00', 0.01207613650203730009, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-8-16 00:00:00', 0.00554782003526623976, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-8-17 00:00:00', 0.00792464685956867018, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-8-18 00:00:00', 0.00635193912962448998, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-8-19 00:00:00', 0.00175665145643393006, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-8-20 00:00:00', 0.00351349986896791998, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-8-21 00:00:00', 0.01940210117852799940, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-8-22 00:00:00', 0.00734906235275372983, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-8-23 00:00:00', 0.01093953751822049868, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-8-24 00:00:00', 0.00896512654496491902, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-8-25 00:00:00', 0.01173858356356789930, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-8-26 00:00:00', 0.00370702893288673988, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-8-27 00:00:00', 0.00042345561512870800, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-8-28 00:00:00', 0.01434940065938530157, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-8-29 00:00:00', 0.01060890246045449910, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-8-30 00:00:00', 0.01127081334174299954, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-8-31 00:00:00', 0.00834075362684656013, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-9-1 00:00:00',  0.00985165578915805050, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-9-2 00:00:00',  0.00119440102558605009, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-9-3 00:00:00',  0.00343127799107278975, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-9-4 00:00:00',  0.01870093072673960008, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-9-5 00:00:00',  0.01672522698412709855, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-9-6 00:00:00',  0.00214246665826085987, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-9-7 00:00:00',  0.01277330501046789954, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-9-8 00:00:00',  0.01945605924807779913, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-9-9 00:00:00',  0.00136733572511802976, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-9-10 00:00:00', 0.00130546802208897990, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-9-11 00:00:00', 0.01501243609270330043, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-9-12 00:00:00', 0.01326243530801889982, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-9-13 00:00:00', 0.01041069726675820060, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-9-14 00:00:00', 0.00596315811136900048, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-9-15 00:00:00', 0.00791573464986320904, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-9-16 00:00:00', 0.00165198664722766017, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-9-17 00:00:00', 0.00095359546111124902, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-9-18 00:00:00', 0.01254809831901269879, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-9-19 00:00:00', 0.00719985394000588995, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-9-20 00:00:00', 0.00676227832227658046, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-9-21 00:00:00', 0.00951560965492409018, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-9-22 00:00:00', 0.00682679886802909069, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-9-23 00:00:00', 0.00029714343906741701, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-9-24 00:00:00', 0.00047679773055562397, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-9-25 00:00:00', 0.00904621820227914999, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-9-26 00:00:00', 0.00708240047295492954, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-9-27 00:00:00', 0.00935388070925795984, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-9-28 00:00:00', 0.01279882157595910001, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-9-29 00:00:00', 0.01084941904469250047, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;
insert into daily_contributions
	(capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
	values (2, '2017-9-30 00:00:00', 0.00000000000000000000, '2017-03-22 00:00:00', '2017-03-30 20:20:20', 8)
	RETURNING id;

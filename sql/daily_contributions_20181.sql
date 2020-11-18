delete from daily_contributions where capture_period_id = 3;
delete from capture_periods where id = 3;
insert into capture_periods values (3, '2018.1', '2017-10-01 03:00:00', '2018-03-31 23:59:59', now(), now());

insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-10-01', 5.83487847398221E-005, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-10-02', 0.0008778245, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-10-03', 0.0008286426, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-10-04', 0.0008197954, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-10-05', 0.0006608649, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-10-06', 0.0008470514, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-10-07', 0.0001165724, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-10-08', 0.0001946978, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-10-09', 0.0010074916, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-10-10', 0.000875183, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-10-11', 0.0002330045, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-10-12', 0.0009325094, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-10-13', 0.0010547636, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-10-14', 0.0003175672, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-10-15', 9.70842161428281E-005, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-10-16', 0.0015664619, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-10-17', 0.0012845097, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-10-18', 0.0016451529, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-10-19', 0.0013069465, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-10-20', 0.0011601329, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-10-21', 0.0004076593, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-10-22', 0.0002655444, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-10-23', 0.0018267696, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-10-24', 0.0016079547, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-10-25', 0.0013383285, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-10-26', 0.0023649728, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-10-27', 0.001965092, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-10-28', 0.0004279148, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-10-29', 0.0005753965, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-10-30', 0.0030779785, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-10-31', 0.0023370695, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-11-01', 0.0006607356, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-11-02', 0.0030096744, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-11-03', 0.0024105957, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-11-04', 0.0005528732, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-11-05', 0.0003987901, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-11-06', 0.0032494541, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-11-07', 0.003510186, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-11-08', 0.0031538153, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-11-09', 0.0034803112, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-11-10', 0.0028944972, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-11-11', 0.0006395238, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-11-12', 0.0005758063, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-11-13', 0.003586101, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-11-14', 0.000697653, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-11-15', 0.0056169971, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-11-16', 0.0080434961, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-11-17', 0.0071310138, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-11-18', 0.0011143944, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-11-19', 0.0008456346, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-11-20', 0.0064541859, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-11-21', 0.0059747473, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-11-22', 0.0057003058, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-11-23', 0.0057520582, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-11-24', 0.0048986633, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-11-25', 0.0008807004, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-11-26', 0.0005720791, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-11-27', 0.0058094417, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-11-28', 0.0049560435, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-11-29', 0.0058132072, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-11-30', 0.0063532049, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-12-01', 0.0044232879, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-12-02', 0.0010108763, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-12-03', 0.0005020652, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-12-04', 0.0063049844, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-12-05', 0.0052162344, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-12-06', 0.0057389526, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-12-07', 0.0042333373, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-12-08', 0.0045780041, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-12-09', 0.0008955565, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-12-10', 0.0005253578, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-12-11', 0.0070401536, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-12-12', 0.0052334457, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-12-13', 0.0055109825, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-12-14', 0.0054649071, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-12-15', 0.0047058165, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-12-16', 0.0005702706, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-12-17', 0.0005320515, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-12-18', 0.0056359089, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-12-19', 0.0057539705, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-12-20', 0.0047706466, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-12-21', 0.0044139323, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-12-22', 0.0033657994, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-12-23', 0.0009598606, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-12-24', 0.000302211, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-12-25', 0.0041022558, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-12-26', 0.005279387, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-12-27', 0.0046550461, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-12-28', 0.0035271393, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-12-29', 0.0008082244, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-12-30', 0.0004002494, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2017-12-31', 0.0004352752, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-01-01', 0.006498373, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-01-02', 0.0085798878, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-01-03', 0.009706796, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-01-04', 0.00862359, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-01-05', 0.0094848551, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-01-06', 0.0012552299, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-01-07', 0.0011753223, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-01-08', 0.0117571898, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-01-09', 0.0102957305, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-01-10', 0.0092075007, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-01-11', 0.0094543003, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-01-12', 0.0088950617, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-01-13', 0.0014382719, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-01-14', 0.0011105345, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-01-15', 0.0115362765, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-01-16', 0.009836913, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-01-17', 0.0120118645, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-01-18', 0.0130881726, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-01-19', 0.0145238757, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-01-20', 0.0033277988, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-01-21', 0.0022773955, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-01-22', 0.021113774, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-01-23', 0.0157365101, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-01-24', 0.0146562627, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-01-25', 0.0164848937, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-01-26', 0.0136458731, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-01-27', 0.0027970714, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-01-28', 0.0018180894, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-01-29', 0.0195257222, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-01-30', 0.0269735484, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-01-31', 0.0254276009, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-02-01', 0.0220251648, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-02-02', 0.0192406978, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-02-03', 0.0038386542, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-02-04', 0.0028101873, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-02-05', 0.0263264092, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-02-06', 0.0262650051, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-02-07', 0.0229282458, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-02-08', 0.0195873778, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-02-09', 0.0156025953, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-02-10', 0.0032443703, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-02-11', 0.0021030724, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-02-12', 0.0204733037, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-02-13', 0.0174485514, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-02-14', 0.0166251008, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-02-15', 0.015685171, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-02-16', 0.0080536984, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-02-17', 0.0020217466, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-02-18', 0.0062268858, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-02-19', 0.0141586791, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-02-20', 0.012357801, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-02-21', 0.0104167683, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-02-22', 0.0093014012, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-02-23', 0.007353479, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-02-24', 0.0010383175, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-02-25', 0.0007666224, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-02-26', 0.0011660107, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-02-27', 0.0006258245, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-02-28', 0.007101716, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-03-01', 0.0075091483, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-03-02', 0.0076226348, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-03-03', 0.0016211509, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-03-04', 0.0013468315, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-03-05', 0.0098387165, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-03-06', 0.008088631, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-03-07', 0.0071719886, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-03-08', 0.0064092477, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-03-09', 0.0058949036, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-03-10', 0.0005888947, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-03-11', 0.0005156273, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-03-12', 0.0057111864, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-03-13', 0.005103327, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-03-14', 0.0045493868, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-03-15', 0.0047685221, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-03-16', 0.0043487212, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-03-17', 0.0007019601, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-03-18', 0.0007886136, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-03-19', 0.0054895535, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-03-20', 0.0043727501, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-03-21', 0.0042141884, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-03-22', 0.003492066, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-03-23', 0.002984979, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-03-24', 0.0007158574, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-03-25', 0.000487319, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-03-26', 0.0036300312, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-03-27', 0.0030852065, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-03-28', 0.0028291197, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-03-29', 0.0025274943, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-03-30', 0.0024076992, now(), now(), 1)
  returning id;
insert into daily_contributions
  (capture_period_id, date, daily_contribution, inserted_at, updated_at, product_line_id)
  values (3, '2018-03-31', 0.000415434, now(), now(), 1)
  returning id;

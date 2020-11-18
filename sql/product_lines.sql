delete from product_lines;
insert into product_lines (id, name, created_at, updated_at) values (1, 'Todas as modalidades e níveis' , '2017-05-31 17:17:05.919351', '2017-05-31 21:24:41.006985');
insert into product_lines (id, name, created_at, updated_at) values (4, 'Graduação Presencial' , '2017-05-31 17:18:14.257975', '2017-05-31 21:25:15.676856');
insert into product_lines (id, name, created_at, updated_at) values (5, 'Pós Graduação Presencial' , '2017-06-07 18:47:47.262822', '2017-06-07 18:47:47.262822');
insert into product_lines (id, name, created_at, updated_at) values (3, 'Pós Graduação EaD' , '2017-05-31 17:17:48.484671', '2017-06-07 18:48:27.800089');
insert into product_lines (id, name, created_at, updated_at) values (2, 'Graduação EaD' , '2017-05-31 17:17:29.588486', '2017-06-07 18:48:44.410045');
insert into product_lines (id, name, created_at, updated_at) values (6, 'Outros Presencial' , '2017-06-07 18:50:16.883766', '2017-06-07 18:50:16.883766');
insert into product_lines (id, name, created_at, updated_at) values (7, 'Outros EaD' , '2017-06-07 18:50:36.497741', '2017-06-07 18:50:36.497741');
insert into product_lines (id, name, created_at, updated_at) values (8, 'Pós Graduação' , '2017-06-07 19:50:40.337583', '2017-06-07 19:50:40.337583');

delete from product_lines_kinds;
insert into product_lines_kinds (id, product_line_id, kind_id) values (1, 1, 1);
insert into product_lines_kinds (id, product_line_id, kind_id) values (2, 2, 3);
insert into product_lines_kinds (id, product_line_id, kind_id) values (3, 3, 3);
insert into product_lines_kinds (id, product_line_id, kind_id) values (8, 5, 1);
insert into product_lines_kinds (id, product_line_id, kind_id) values (6, 4, 1);
insert into product_lines_kinds (id, product_line_id, kind_id) values (7, 1, 3);
insert into product_lines_kinds (id, product_line_id, kind_id) values (9, 6, 1);
insert into product_lines_kinds (id, product_line_id, kind_id) values (10, 7, 3);
insert into product_lines_kinds (id, product_line_id, kind_id) values (11, 8, 3);
insert into product_lines_kinds (id, product_line_id, kind_id) values (12, 8, 1);


delete from product_lines_levels;

insert into product_lines_levels(id, product_line_id, level_id) values (  1, 1, 1);
insert into product_lines_levels(id, product_line_id, level_id) values (  2, 2, 1);
insert into product_lines_levels(id, product_line_id, level_id) values (  3, 3, 7);
insert into product_lines_levels(id, product_line_id, level_id) values ( 11, 5, 7);
insert into product_lines_levels(id, product_line_id, level_id) values ( 12, 6, 14);
insert into product_lines_levels(id, product_line_id, level_id) values ( 13, 6, 12);
insert into product_lines_levels(id, product_line_id, level_id) values (  7, 4, 1);
insert into product_lines_levels(id, product_line_id, level_id) values (  8, 1, 14);
insert into product_lines_levels(id, product_line_id, level_id) values (  9, 1, 12);
insert into product_lines_levels(id, product_line_id, level_id) values ( 10, 1, 7);
insert into product_lines_levels(id, product_line_id, level_id) values ( 14, 7, 14);
insert into product_lines_levels(id, product_line_id, level_id) values ( 15, 7, 12);
insert into product_lines_levels(id, product_line_id, level_id) values ( 16, 8, 7);
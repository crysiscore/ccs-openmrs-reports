-- Xipamanine DB
mysqldump -uroot  reports reporting_report_design reporting_report_design_resource reporting_report_processor reporting_report_request serialized_object report_object > pepfar_mer3_1_openmrs_06042020.sql


-- Xipamanine DB 06/05/2020
mysqldump -uroot  reports reporting_report_design reporting_report_design_resource reporting_report_processor reporting_report_request serialized_object report_object > ccs_reports_06_05_2020.sql


-- Xipamanine DB 22/06/2020
mysqldump -uroot  xipamanine reporting_report_design reporting_report_design_resource reporting_report_processor reporting_report_request serialized_object report_object > ccs_reports_22_06_2020.sql


-- Xipamanine DB 18/08/2020
mysqldump -uroot  xipamanine reporting_report_design reporting_report_design_resource reporting_report_processor reporting_report_request serialized_object report_object > ccs_reports_18_08_2020.sql


-- Xipamanine DB 18/08/2020
mysqldump -uroot -p xipamanine reporting_report_design reporting_report_design_resource reporting_report_processor reporting_report_request serialized_object report_object > ccs_reports_31_08_2020.sql

-- Xipamanine DB 18/08/2020
mysqldump  -uesaude -p -h127.0.0.1 -P3306 xipamanine reporting_report_design reporting_report_design_resource reporting_report_processor reporting_report_request serialized_object report_object > ccs_reports_17_06_2021.sql 

-- Xipamanine DB 23/06/2021
mysqldump   --column-statistics=0 -uroot  -p -h127.0.0.1 -P3306  openmrs  reporting_report_design reporting_report_design_resource reporting_report_processor reporting_report_request serialized_object report_object > ccs_reports_23_06_2021.sql

-- openmrs DB 25/10/2021
mysqldump  -uesaude -p -h127.0.0.1 -P3306 openmrs reporting_report_design reporting_report_design_resource reporting_report_processor reporting_report_request serialized_object report_object > ccs_reports_01_03_2023.sql 

-- openmrs 0/04/2023
mysqldump  -uesaude -p -h127.0.0.1 -P3306 openmrs reporting_report_design reporting_report_design_resource reporting_report_processor reporting_report_request serialized_object report_object > ccs_reports_10_04_2023.sql 

-- openmrs 09/01/2024
mysqldump  -uslave -p -h127.0.0.1 -P3306 reportsdb reporting_report_design reporting_report_design_resource reporting_report_processor reporting_report_request serialized_object report_object > ccs_reports_09_01_2024.sql 



-- openmrs 08/02/2024
mysqldump  -uslave -p -h127.0.0.1 -P3306 xipamanine reporting_report_design reporting_report_design_resource reporting_report_processor reporting_report_request serialized_object report_object > ccs_reports_08_02_2024.sql 
4nUvt27aZ

-- openmrs 01/04/2024
mysqldump --column-statistics=0  -uslave -p4nUvt27aZ -h127.0.0.1 -P3306 xipamanine reporting_report_design reporting_report_design_resource reporting_report_processor reporting_report_request serialized_object report_object > ccs_reports_23_05_2025.sql 

create table authorize_gateway_result_log (
    	transaction_id varchar2(20) not null,
	txn_attempted_type varchar2(18), 
	txn_attempted_time date, 
	response varchar2(400), 
	response_code varchar2(1), 
	response_reason_code varchar2(2), 
	response_reason_text varchar2(100), 
	auth_code varchar2(6), 
	avs_code varchar2(3), 
	amount number not null, 
    	constraint authorize_log_pk primary key(transaction_id)
); 

@authorize-gateway-sc-create.sql;

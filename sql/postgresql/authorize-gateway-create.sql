create table authorize_gateway_result_log (
    transaction_id 		varchar(20) not null,
    txn_attempted_type  	varchar(18),
    txn_attempted_time 		timestamptz,
    response 			varchar(400),
    response_code 		varchar(1),
    response_reason_code 	varchar(2),
    response_reason_text       	varchar(100),
    auth_code                  	varchar(6),
    avs_code                   	varchar(3),
    amount                     	numeric not null
);

create index authorize_gateway_result_log_transaction_id on authorize_gateway_result_log(transaction_id);

\i authorize-gateway-sc-create.sql
